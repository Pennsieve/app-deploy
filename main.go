package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

var TerraformDirectory = "/service/terraform"
var TerraformStateDirectory = "/service/terraform/remote-state"
var TerraformDeploymentsDirectory = "/service/application-deployments"

func main() {
	cmdPtr := flag.String("cmd", "plan", "command to execute")
	flag.Parse()

	if *cmdPtr == "plan-state" {
		log.Println("Initializing state")
		// init
		terraformInit := NewExecution(exec.Command("terraform", "init"),
			TerraformStateDirectory,
			nil)
		if err := terraformInit.Run(); err != nil {
			log.Println("terraform init error", terraformInit.GetStdErr())
		}
		log.Println("terraform init", terraformInit.GetStdOut())

		// plan
		terraformPlan := NewExecution(exec.Command("terraform", "plan", "-out=tfplan"),
			TerraformStateDirectory,
			map[string]string{
				"AWS_ACCESS_KEY_ID":     os.Getenv("AWS_ACCESS_KEY_ID"),
				"AWS_SECRET_ACCESS_KEY": os.Getenv("AWS_SECRET_ACCESS_KEY"),
				"AWS_DEFAULT_REGION":    os.Getenv("AWS_DEFAULT_REGION"),
			})
		if err := terraformPlan.Run(); err != nil {
			log.Println("terraform plan error", terraformPlan.GetStdErr())
		}
		log.Println("terraform plan", terraformPlan.GetStdOut())
	}

	if *cmdPtr == "apply-state" {
		log.Println("Running apply ...")
		terraformApply := NewExecution(exec.Command("terraform", "apply", "tfplan"),
			TerraformStateDirectory,
			nil)
		if err := terraformApply.Run(); err != nil {
			log.Println("terraform apply error", terraformApply.GetStdErr())
		}
		log.Println("terraform apply", terraformApply.GetStdOut())
	}

	if *cmdPtr == "destroy-state" {
		log.Println("Running destroy ...")
		terraformDestroy := NewExecution(exec.Command("terraform", "apply", "-destroy", "-auto-approve"),
			TerraformStateDirectory,
			nil)
		if err := terraformDestroy.Run(); err != nil {
			log.Println("terraform destroy error", terraformDestroy.GetStdErr())
		}
		log.Println("terraform destroy", terraformDestroy.GetStdOut())
	}

	if *cmdPtr == "plan" {
		log.Println("Running init and plan ...")
		// init
		backendFileLocation := fmt.Sprintf("%s/%s", TerraformDeploymentsDirectory, os.Getenv("TF_BACKEND_FILE_LOCATION"))
		initCmd := fmt.Sprintf("terraform init -force-copy -backend-config=%s", backendFileLocation)
		terraformInit := NewExecution(exec.Command("bash", "-c", initCmd),
			TerraformDirectory,
			nil)
		if err := terraformInit.Run(); err != nil {
			log.Println("terraform init error", terraformInit.GetStdErr())
		}
		log.Println("terraform init", terraformInit.GetStdOut())

		// plan
		varFileLocation := fmt.Sprintf("%s/%s", TerraformDeploymentsDirectory, os.Getenv("TF_VAR_FILE_LOCATION"))
		planCmd := fmt.Sprintf("terraform plan -out=tfplan -var-file=%s", varFileLocation)
		terraformPlan := NewExecution(exec.Command("bash", "-c", planCmd),
			TerraformDirectory,
			map[string]string{
				"AWS_ACCESS_KEY_ID":     os.Getenv("AWS_ACCESS_KEY_ID"),
				"AWS_SECRET_ACCESS_KEY": os.Getenv("AWS_SECRET_ACCESS_KEY"),
				"AWS_DEFAULT_REGION":    os.Getenv("AWS_DEFAULT_REGION"),
			})
		if err := terraformPlan.Run(); err != nil {
			log.Println("terraform plan error", terraformPlan.GetStdErr())
		}
		log.Println("terraform plan", terraformPlan.GetStdOut())
	}

	if *cmdPtr == "apply" {
		log.Println("Running apply ...")
		terraformApply := NewExecution(exec.Command("terraform", "apply", "tfplan"),
			TerraformDirectory,
			nil)
		if err := terraformApply.Run(); err != nil {
			log.Println("terraform apply error", terraformApply.GetStdErr())
		}
		log.Println("terraform apply", terraformApply.GetStdOut())
	}

	if *cmdPtr == "destroy" {
		log.Println("Running destroy ...")
		terraformDestroy := NewExecution(exec.Command("terraform", "apply", "-destroy", "-auto-approve"),
			TerraformDirectory,
			nil)
		if err := terraformDestroy.Run(); err != nil {
			log.Println("terraform destroy error", terraformDestroy.GetStdErr())
		}
		log.Println("terraform destroy", terraformDestroy.GetStdOut())
	}

	if *cmdPtr == "output" {
		log.Println("Outputting values ...")
		terraformOutput := NewExecution(exec.Command("terraform", "output"),
			TerraformDirectory,
			nil)
		if err := terraformOutput.Run(); err != nil {
			log.Println("terraform output error", terraformOutput.GetStdErr())
		}
		log.Println(terraformOutput.GetStdOut())
	}

	if *cmdPtr == "graph" {
		log.Println("generating graph ...")
		pipeCmd := "terraform graph -draw-cycles | dot -Tsvg > graph.svg"
		terraformOutput := NewExecution(exec.Command("bash", "-c", pipeCmd),
			TerraformDirectory,
			nil)
		if err := terraformOutput.Run(); err != nil {
			log.Println("terraform graph error", terraformOutput.GetStdErr())
		}
		log.Println("graph svg generated")
	}

	log.Println("done")
}

type Executioner interface {
	Run() error
	GetStdOut() string
	GetStdErr() string
}

type Execution struct {
	Cmd    *exec.Cmd
	StdOut *strings.Builder
	StdErr *strings.Builder
}

func NewExecution(cmd *exec.Cmd, dir string, envVars map[string]string) Executioner {
	var stdout strings.Builder
	var stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	cmd.Dir = dir
	cmd = setEnvVars(cmd, envVars)

	return &Execution{cmd, &stdout, &stderr}
}

func setEnvVars(cmd *exec.Cmd, envVars map[string]string) *exec.Cmd {
	cmd.Env = os.Environ()
	for k, v := range envVars {
		cmd.Env = append(cmd.Env, fmt.Sprintf("%s=%s", k, v))
	}
	return cmd
}

func (c *Execution) Run() error {
	return c.Cmd.Run()
}

func (c *Execution) GetStdOut() string {
	return c.StdOut.String()
}

func (c *Execution) GetStdErr() string {
	return c.StdErr.String()
}
