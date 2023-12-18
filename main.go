package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
)

var TerraformDirectory = "/service/terraform"
var TerraformStateDirectory = "/service/terraform/remote-state"
var TerraformDeploymentsDirectory = "/service/application-deployments"
var TerraformGatewayDirectory = "/service/terraform/internet-gateway"

func main() {
	cmdPtr := flag.String("cmd", "plan", "command to execute")
	flag.Parse()

	// Remote State Management - S3 Backend (once-off)
	if *cmdPtr == "create-backend" || *cmdPtr == "delete-backend" {
		cmd := exec.Command("/bin/sh", "./scripts/remote-state.sh", TerraformStateDirectory, *cmdPtr)
		out, err := cmd.Output()
		if err != nil {
			log.Fatalf("error %s", err)
		}
		output := string(out)
		fmt.Println(output)
	}

	// Creating a route in route table (once-off)
	if *cmdPtr == "create-route" || *cmdPtr == "delete-route" {
		cmd := exec.Command("/bin/sh", "./scripts/routing-table.sh", TerraformGatewayDirectory, *cmdPtr)
		out, err := cmd.Output()
		if err != nil {
			log.Fatalf("error %s", err)
		}
		output := string(out)
		fmt.Println(output)
	}

	// Infrastructure creation
	planLocation := fmt.Sprintf("%s/tfplan", os.Getenv("WORKING_DATA_DIR"))
	varFileLocation := fmt.Sprintf("%s/%s", TerraformDeploymentsDirectory, os.Getenv("TF_VAR_FILE_LOCATION"))
	svgLocation := fmt.Sprintf("%s/graph.svg", os.Getenv("WORKING_DATA_DIR"))
	backendFileLocation := fmt.Sprintf("%s/%s", TerraformDeploymentsDirectory, os.Getenv("TF_BACKEND_FILE_LOCATION"))

	if *cmdPtr == "status" || *cmdPtr == "create" || *cmdPtr == "destroy" {
		cmd := exec.Command("/bin/sh", "./scripts/infrastructure.sh",
			TerraformDirectory, os.Getenv("WORKING_DATA_DIR"),
			backendFileLocation, planLocation, varFileLocation, svgLocation, *cmdPtr)
		out, err := cmd.Output()
		if err != nil {
			log.Fatalf("error %s", err)
		}
		output := string(out)
		fmt.Println(output)
	}

	log.Println("done")
}
