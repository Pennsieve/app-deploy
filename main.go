package main

import (
	"flag"
	"fmt"
	"log"
	"os/exec"
)

var TerraformStateDirectory = "/service/terraform/remote-state"
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
	if *cmdPtr == "status" || *cmdPtr == "create" || *cmdPtr == "destroy" {
		cmd := exec.Command("/bin/sh", "./scripts/infrastructure.sh", *cmdPtr)
		out, err := cmd.Output()
		if err != nil {
			log.Fatalf("error %s", err)
		}
		output := string(out)
		fmt.Println(output)
	}

	log.Println("done")
}
