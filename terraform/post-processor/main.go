package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
)

var CommandRunDirectory = "/service"

func main() {
	fmt.Println("Welcome to the Post-Processor")
	integrationID := os.Getenv("INTEGRATION_ID")
	environment := os.Getenv("ENVIRONMENT")

	// get integration
	sessionToken := os.Getenv("SESSION_TOKEN")
	apiHost2 := os.Getenv("PENNSIEVE_API_HOST2")
	// TODO: should get new sessiontoken in the event main application runs for long
	integrationResponse, err := getIntegration(apiHost2, integrationID, sessionToken)
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(string(integrationResponse))
	var integration Integration
	if err := json.Unmarshal(integrationResponse, &integration); err != nil {
		fmt.Println(err.Error())
	}
	fmt.Println(integration)

	datasetID := integration.DatasetNodeID

	var target_path string
	if integration.Params != nil {
		params := integration.Params.(map[string]interface{})

		target_path_val, ok := params["target_path"]
		if ok {
			target_path = fmt.Sprintf("%v", target_path_val)
		}
	}
	fmt.Println("target path", target_path)

	fmt.Println("ENVIRONMENT: ", environment)
	fmt.Println("PENNSIEVE_API_HOST: ", os.Getenv("PENNSIEVE_API_HOST"))
	fmt.Println("PENNSIEVE_UPLOAD_BUCKET: ", os.Getenv("PENNSIEVE_UPLOAD_BUCKET"))
	if environment == "prod" {
		fmt.Println("unsetting variables")
		apiHostErr := os.Unsetenv("PENNSIEVE_API_HOST")
		if apiHostErr != nil {
			fmt.Println("error unsetting variable PENNSIEVE_API_HOST:",
				apiHostErr)
		}
		err := os.Unsetenv("PENNSIEVE_UPLOAD_BUCKET")
		if err != nil {
			fmt.Println("error unsetting variable PENNSIEVE_UPLOAD_BUCKET:",
				err)
		}
	}
	fmt.Println("PENNSIEVE_API_HOST: ", os.Getenv("PENNSIEVE_API_HOST"))
	fmt.Println("PENNSIEVE_UPLOAD_BUCKET: ", os.Getenv("PENNSIEVE_UPLOAD_BUCKET"))

	fmt.Println("API_KEY: ", os.Getenv("PENNSIEVE_API_KEY"))
	fmt.Println("API_SECRET: ", os.Getenv("PENNSIEVE_API_SECRET"))
	fmt.Println("DATASET_ID: ", datasetID)
	fmt.Println("INTEGRATION_ID: ", integrationID)

	cmd := exec.Command("/bin/sh", "./agent.sh", datasetID, integrationID, target_path)
	out, err := cmd.Output()
	if err != nil {
		log.Fatalf("error %s", err)
	}
	output := string(out)
	fmt.Println(output)
}

type Integration struct {
	Uuid          string      `json:"uuid"`
	ApplicationID int64       `json:"applicationId"`
	DatasetNodeID string      `json:"datasetId"`
	PackageIDs    []string    `json:"packageIds"`
	Params        interface{} `json:"params"`
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
