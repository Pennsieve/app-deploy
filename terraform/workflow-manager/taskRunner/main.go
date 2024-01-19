package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	"github.com/aws/aws-sdk-go-v2/service/ecs/types"
	"github.com/aws/aws-sdk-go/aws"
)

type Runner interface {
	Run()
}

type TaskRunner struct {
}

func main() {
	fmt.Println("invoking task ...")

	TaskDefinitionArn := os.Getenv("TASK_DEFINITION_NAME")
	subIdStr := os.Getenv("SUBNET_IDS")
	SubNetIds := strings.Split(subIdStr, ",")
	cluster := os.Getenv("CLUSTER_NAME")
	SecurityGroup := os.Getenv("SECURITY_GROUP_ID")
	TaskDefContainerName := os.Getenv("CONTAINER_NAME")
	apiKey := os.Getenv("PENNSIEVE_API_KEY")
	apiSecret := os.Getenv("PENNSIEVE_API_SECRET")
	environment := os.Getenv("ENVIRONMENT")
	apiHost := os.Getenv("PENNSIEVE_API_HOST")
	apiHost2 := os.Getenv("PENNSIEVE_API_HOST2")
	integrationID := os.Getenv("INTEGRATION_ID")
	baseDir := "/mnt/efs"
	sessionToken := os.Getenv("SESSION_TOKEN")

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("LoadDefaultConfig: %v\n", err)
	}

	client := ecs.NewFromConfig(cfg)
	apiKeyKey := "PENNSIEVE_API_KEY"
	apiSecretKey := "PENNSIEVE_API_SECRET"
	apihostKey := "PENNSIEVE_API_HOST"
	apihost2Key := "PENNSIEVE_API_HOST2"
	integrationIDKey := "INTEGRATION_ID"
	environmentKey := "ENVIRONMENT"
	baseDirKey := "BASE_DIR"
	sessionTokenKey := "SESSION_TOKEN"

	log.Println("Initiating Task.")
	runTaskIn := &ecs.RunTaskInput{
		TaskDefinition: aws.String(TaskDefinitionArn),
		Cluster:        aws.String(cluster),
		NetworkConfiguration: &types.NetworkConfiguration{
			AwsvpcConfiguration: &types.AwsVpcConfiguration{
				Subnets:        SubNetIds,
				SecurityGroups: []string{SecurityGroup},
				AssignPublicIp: types.AssignPublicIpEnabled,
			},
		},
		Overrides: &types.TaskOverride{
			ContainerOverrides: []types.ContainerOverride{
				{
					Name: &TaskDefContainerName,
					Environment: []types.KeyValuePair{
						{
							Name:  &integrationIDKey,
							Value: &integrationID,
						},
						{
							Name:  &apiKeyKey,
							Value: &apiKey,
						},
						{
							Name:  &baseDirKey,
							Value: &baseDir,
						},
						{
							Name:  &apiSecretKey,
							Value: &apiSecret,
						},
						{
							Name:  &apihostKey,
							Value: &apiHost,
						},
						{
							Name:  &apihost2Key,
							Value: &apiHost2,
						},
						{
							Name:  &environmentKey,
							Value: &environment,
						},
						{
							Name:  &sessionTokenKey,
							Value: &sessionToken,
						},
					},
				},
			},
		},
		LaunchType: types.LaunchTypeFargate,
	}

	taskResponse, err := client.RunTask(context.Background(), runTaskIn)
	for _, task := range taskResponse.Tasks {
		log.Printf("Waiting until task %s has stopped", *task.TaskArn)
	}
	if err != nil {
		log.Fatalf("error running task: %v\n", err)
	}
	log.Println("task complete")
}
