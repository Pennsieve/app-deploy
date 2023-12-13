package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
)

var CommandRunDirectory = "/service"

func main() {
	fmt.Println("Welcome to the Post-Processor")
	datasetID := os.Getenv("DATASET_ID")
	integrationID := os.Getenv("INTEGRATION_ID")
	environment := os.Getenv("ENVIRONMENT")
	if environment == "prod" {
		os.Setenv("PENNSIEVE_API_HOST", "")
	}
	cmd := exec.Command("/bin/sh", "./agent.sh", datasetID, integrationID)
	out, err := cmd.Output()
	if err != nil {
		log.Fatalf("error %s", err)
	}
	output := string(out)
	fmt.Println(output)
}
