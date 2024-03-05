package main

import (
	"flag"
	"fmt"
	"log"
	"os/exec"
)

var TerraformStateDirectory = "/service/terraform/remote-state"
var TerraformAppStateDirectory = "/service/terraform/application-state"
var TerraformGatewayDirectory = "/service/terraform/internet-gateway"
var TerraformApplicationDirectory = "/service/terraform/application-wrapper"
var TerraformStatusServiceDirectory = "/service/terraform/status-service"
var TerraformComputeServiceDirectory = "/service/terraform/compute-node-service"

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

	// Remote State Application Management
	if *cmdPtr == "create-application-state-app" || *cmdPtr == "delete-application-state-app" {
		cmd := exec.Command("/bin/sh", "./scripts/application-state-app.sh", TerraformAppStateDirectory, *cmdPtr)
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
	if *cmdPtr == "status" || *cmdPtr == "create" || *cmdPtr == "destroy" {
		cmd := exec.Command("/bin/sh", "./scripts/infrastructure.sh", *cmdPtr)
		out, err := cmd.Output()
		if err != nil {
			log.Fatalf("error %s", err)
		}
		output := string(out)
		fmt.Println(output)
	}

	// application creation
	if *cmdPtr == "create-application" || *cmdPtr == "destroy-application" {
		cmd := exec.Command("/bin/sh", "./scripts/application.sh", TerraformApplicationDirectory, *cmdPtr)
		out, err := cmd.Output()
		output := string(out)
		fmt.Println(output)
		if err != nil {
			log.Fatalf("error %s", err.Error())
		}
	}

	// status service
	if *cmdPtr == "create-status-service" || *cmdPtr == "destroy-status-service" {
		cmd := exec.Command("/bin/sh", "./scripts/status-service.sh", TerraformStatusServiceDirectory, *cmdPtr)
		out, err := cmd.Output()
		output := string(out)
		fmt.Println(output)
		if err != nil {
			log.Fatalf("error %s", err.Error())
		}
	}

	// compute node service
	if *cmdPtr == "create-compute-node" || *cmdPtr == "destroy-compute-node" {
		cmd := exec.Command("/bin/sh", "./scripts/compute-node-service.sh", TerraformComputeServiceDirectory, *cmdPtr)
		out, err := cmd.Output()
		output := string(out)
		fmt.Println(output)
		if err != nil {
			log.Fatalf("error %s", err.Error())
		}
	}

	log.Println("done")
}
