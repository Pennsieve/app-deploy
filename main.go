package main

import (
	"flag"
	"fmt"
	"log"
	"os/exec"
)

var TerraformStateDirectory = "/service/terraform/remote-state"
var TerraformAppStateDirectory = "/service/terraform/remote-state-application"
var TerraformGatewayDirectory = "/service/terraform/internet-gateway"
var TerraformApplicationDirectory = "/service/terraform/application-wrapper"

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
	if *cmdPtr == "create-remote-state-app" || *cmdPtr == "remote-state-app" {
		cmd := exec.Command("/bin/sh", "./scripts/remote-state-application.sh", TerraformAppStateDirectory, *cmdPtr)
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

	log.Println("done")
}
