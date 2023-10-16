package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func main() {
	log.Println("Running terraform commands ...")

	terraformInit := NewExecution(exec.Command("terraform", "init"),
		"/service",
		nil)
	if err := terraformInit.Run(); err != nil {
		log.Println("terraform init error", terraformInit.GetStdErr())
	}
	log.Println("terraform init", terraformInit.GetStdOut())

	terraformPlan := NewExecution(exec.Command("terraform", "plan"),
		"/service",
		map[string]string{
			"AWS_ACCESS_KEY_ID":     os.Getenv("AWS_ACCESS_KEY_ID"),
			"AWS_SECRET_ACCESS_KEY": os.Getenv("AWS_SECRET_ACCESS_KEY"),
			"AWS_DEFAULT_REGION":    os.Getenv("AWS_DEFAULT_REGION"),
		})
	if err := terraformPlan.Run(); err != nil {
		log.Println("terraform plan error", terraformInit.GetStdErr())
	}
	log.Println("terraform plan", terraformPlan.GetStdOut())

	log.Println("done")
}

type Runner interface {
	Run() error
	GetStdOut() string
	GetStdErr() string
}

type Execution struct {
	Cmd    *exec.Cmd
	StdOut *strings.Builder
	StdErr *strings.Builder
}

func NewExecution(cmd *exec.Cmd, dir string, envVars map[string]string) Runner {
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
