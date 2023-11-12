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
	cmd := exec.Command("/bin/sh", "./agent.sh", datasetID, integrationID)
	out, err := cmd.Output()
	if err != nil {
		log.Fatalf("error %s", err)
	}
	output := string(out)
	fmt.Println(output)
}
