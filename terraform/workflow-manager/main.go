package main

import (
	"log"
	"log/slog"
	"os"
	"os/exec"
	"strings"
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	log.Println("Welcome to the WorkflowManager")
	log.Println("Starting pipeline")

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
}
