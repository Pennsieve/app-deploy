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

func main() {
	cmdPtr := flag.String("cmd", "plan", "command to execute")
	flag.Parse()

	if *cmdPtr == "plan" {
		log.Println("Running init and plan ...")
		// init
		terraformInit := NewExecution(exec.Command("terraform", "init"),
			TerraformDirectory,
			nil)
		if err := terraformInit.Run(); err != nil {
			log.Println("terraform init error", terraformInit.GetStdErr())
		}
		log.Println("terraform init", terraformInit.GetStdOut())

		// plan
		terraformPlan := NewExecution(exec.Command("terraform", "plan", "-out=tfplan"),
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
		// apply
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
		// apply
		terraformDestroy := NewExecution(exec.Command("terraform", "apply", "-destroy", "-auto-approve"),
			TerraformDirectory,
			nil)
		if err := terraformDestroy.Run(); err != nil {
			log.Println("terraform destroy error", terraformDestroy.GetStdErr())
		}
		log.Println("terraform destroy", terraformDestroy.GetStdOut())
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
