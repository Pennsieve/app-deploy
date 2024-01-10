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
	fmt.Println("TARGET_PATH: ", os.Getenv("TARGET_PATH"))

	cmd := exec.Command("/bin/sh", "./agent.sh", datasetID, integrationID)
	out, err := cmd.Output()
	if err != nil {
		log.Fatalf("error %s", err)
	}
	output := string(out)
	fmt.Println(output)
}
