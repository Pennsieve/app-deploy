package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"

	"log/slog"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	"github.com/aws/aws-sdk-go-v2/service/ecs/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/google/uuid"
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	integrationID := os.Getenv("INTEGRATION_ID")
	baseDir := os.Getenv("BASE_DIR")
	if integrationID == "" {
		id := uuid.New()
		integrationID = id.String()
	}
	if baseDir == "" {
		baseDir = "/mnt/efs"
	}

	logger.Info(integrationID)
	// create subdirectories
	err := os.Chdir(baseDir)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}

	err = os.MkdirAll(fmt.Sprintf("input/%s", integrationID), 0755)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	err = os.MkdirAll("output", 0777)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	err = os.Chown("output", 1000, 1000)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	err = os.MkdirAll(fmt.Sprintf("output/%s", integrationID), 0777)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	err = os.Chown(fmt.Sprintf("output/%s", integrationID), 1000, 1000)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}

	// get input files
	sessionToken := os.Getenv("SESSION_TOKEN")
	apiHost := os.Getenv("PENNSIEVE_API_HOST")
	integrationResponse, err := getIntegration("https://api2.pennsieve.net", integrationID, sessionToken) // TODO: pass api_host2
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(string(integrationResponse))
	var integration Integration
	if err := json.Unmarshal(integrationResponse, &integration); err != nil {
		logger.ErrorContext(context.Background(), err.Error())
	}
	fmt.Println(integration)

	datasetID := integration.DatasetNodeID
	manifest, err := getPresignedUrls(apiHost, getPackageIds(integration.PackageIDs), sessionToken)
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(string(manifest))
	var payload Manifest
	if err := json.Unmarshal(manifest, &payload); err != nil {
		logger.ErrorContext(context.Background(), err.Error())
	}

	// Process - for this example, place input files directly into output dir
	// ideally this step copies input files into the <input> dir
	fmt.Println(payload.Data)
	for _, d := range payload.Data {
		cmd := exec.Command("wget", "-O", d.FileName, d.Url)
		cmd.Dir = fmt.Sprintf("output/%s", integrationID)
		var out strings.Builder
		var stderr strings.Builder
		cmd.Stdout = &out
		cmd.Stderr = &stderr
		if err := cmd.Run(); err != nil {
			logger.Error(err.Error(),
				slog.String("error", stderr.String()))
		}
	}

	// invoke post-processor
	TaskDefinitionArn := os.Getenv("TASK_DEFINITION_NAME_POST")
	subIdStr := os.Getenv("SUBNET_IDS")
	SubNetIds := strings.Split(subIdStr, ",")
	cluster := os.Getenv("CLUSTER_NAME")
	SecurityGroup := os.Getenv("SECURITY_GROUP_ID")
	TaskDefContainerName := os.Getenv("CONTAINER_NAME_POST")
	apiKey := os.Getenv("PENNSIEVE_API_KEY")
	apiSecret := os.Getenv("PENNSIEVE_API_SECRET")
	agentHome := os.Getenv("PENNSIEVE_AGENT_HOME")
	upload_bucket := os.Getenv("PENNSIEVE_UPLOAD_BUCKET")

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("LoadDefaultConfig: %v\n", err)
	}

	client := ecs.NewFromConfig(cfg)
	apiKeyKey := "PENNSIEVE_API_KEY"
	apiSecretKey := "PENNSIEVE_API_SECRET"
	apihostKey := "PENNSIEVE_API_HOST"
	agentHomeKey := "PENNSIEVE_AGENT_HOME"
	integrationIDKey := "INTEGRATION_ID"
	datasetIDKey := "DATASET_ID"
	uploadBucketKey := "PENNSIEVE_UPLOAD_BUCKET"

	log.Println("Initiating post processing Task.")
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
							Name:  &apiKeyKey,
							Value: &apiKey,
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
							Name:  &agentHomeKey,
							Value: &agentHome,
						},
						{
							Name:  &integrationIDKey,
							Value: &integrationID,
						},
						{
							Name:  &datasetIDKey,
							Value: &datasetID,
						},
						{
							Name:  &uploadBucketKey,
							Value: &upload_bucket,
						},
					},
				},
			},
		},
		LaunchType: types.LaunchTypeFargate,
	}

	_, err = client.RunTask(context.Background(), runTaskIn)
	if err != nil {
		log.Fatalf("error running task: %v\n", err)
	}

	logger.Info("Processing complete")
}

type Packages struct {
	NodeIds []string `json:"nodeIds"`
}

type Manifest struct {
	Data []ManifestData `json:"data"`
}

type ManifestData struct {
	NodeId   string   `json:"nodeId"`
	FileName string   `json:"fileName"`
	Path     []string `json:"path"`
	Url      string   `json:"url"`
}

type Integration struct {
	Uuid          string      `json:"uuid"`
	ApplicationID int64       `json:"applicationId"`
	DatasetNodeID string      `json:"datasetId"`
	PackageIDs    []string    `json:"packageIds"`
	Params        interface{} `json:"params"`
}

func getPresignedUrls(apiHost string, packages Packages, sessionToken string) ([]byte, error) {
	url := fmt.Sprintf("%s/packages/download-manifest?api_key=%s", apiHost, sessionToken)
	b, err := json.Marshal(packages)
	if err != nil {
		return nil, err
	}
	fmt.Println(string(b))

	payload := strings.NewReader(string(b))

	req, _ := http.NewRequest("POST", url, payload)

	req.Header.Add("accept", "*/*")
	req.Header.Add("content-type", "application/json")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	return body, nil
}

func getPackageIds(packageIds []string) Packages {
	return Packages{
		NodeIds: packageIds,
	}
}

func getIntegration(apiHost string, integrationId string, sessionToken string) ([]byte, error) {
	url := fmt.Sprintf("%s/integrations/%s", apiHost, integrationId)

	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Add("accept", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", sessionToken))

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	return body, nil
}
