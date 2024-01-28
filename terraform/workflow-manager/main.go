package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"log/slog"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

const (
	visibilityTimeout = 60 * 10
	waitingTimeout    = 20
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	log.Println("Welcome to the WorkflowManager")
	log.Println("Starting pipeline")

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("LoadDefaultConfig: %v\n", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt, syscall.SIGTERM)

	queueUrl := os.Getenv("SQS_URL")
	log.Printf("QUEUE_URL: %s", queueUrl)

	sqsSvc := sqs.NewFromConfig(cfg)

loop:
	for {
		select {
		case <-signalChan: //if get SIGTERM
			log.Println("Got SIGTERM signal, cancelling the context")
			cancel() //cancel context

		default:
			_, err := processSQS(ctx, sqsSvc, queueUrl, logger)

			if err != nil {
				if errors.Is(err, context.Canceled) {
					log.Printf("stop processing, context is cancelled %v", err)
					break loop
				}

				log.Fatalf("error processing SQS %v", err)
			}
		}
	}
	log.Println("service is safely stopped")

}

type MsgType struct {
	Message string `json:"message"`
}

func processSQS(ctx context.Context, sqsSvc *sqs.Client, queueUrl string, logger *slog.Logger) (bool, error) {
	input := &sqs.ReceiveMessageInput{
		QueueUrl:            &queueUrl,
		MaxNumberOfMessages: 1,
		VisibilityTimeout:   visibilityTimeout,
		WaitTimeSeconds:     waitingTimeout, // use long polling
	}

	resp, err := sqsSvc.ReceiveMessage(ctx, input)

	if err != nil {
		return false, fmt.Errorf("error receiving message %w", err)
	}

	log.Printf("received messages: %v", len(resp.Messages))
	if len(resp.Messages) == 0 {
		return false, nil
	}

	for _, msg := range resp.Messages {
		var newMsg MsgType
		id := *msg.MessageId

		err := json.Unmarshal([]byte(*msg.Body), &newMsg)
		if err != nil {
			return false, fmt.Errorf("error unmarshalling %w", err)
		}

		log.Printf("message id %s is received from SQS: %#v", id, newMsg.Message)

		// run pipeline
		cmd := exec.Command("nextflow", "run", "./workflows/pennsieve.nf", "-ansi-log", "false")
		cmd.Dir = "/service"
		var stdout strings.Builder
		var stderr strings.Builder
		cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		if err := cmd.Run(); err != nil {
			logger.Error(err.Error(),
				slog.String("error", stderr.String()))
		}
		log.Println(stdout.String())

		_, err = sqsSvc.DeleteMessage(ctx, &sqs.DeleteMessageInput{
			QueueUrl:      &queueUrl,
			ReceiptHandle: msg.ReceiptHandle,
		})

		if err != nil {
			return false, fmt.Errorf("error deleting message from SQS %w", err)
		}
		log.Printf("message id %s is deleted from queue", id)

	}
	return true, nil
}
