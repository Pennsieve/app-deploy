package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

var CommandRunDirectory = "/root/"

func main() {
	fmt.Println("Welcome to the Post-Processor")

	log.Println("Starting pennsieve agent ...")
	agent := NewExecution(exec.Command("./pennsieve", "agent"),
		CommandRunDirectory,
		nil)
	if err := agent.Run(); err != nil {
		log.Println("pennsieve error", agent.GetStdErr())
	}
	log.Println("agent -> ", agent.GetStdOut())

	log.Println("Running whoami ...")
	whoami := NewExecution(exec.Command("./pennsieve", "whoami"),
		CommandRunDirectory,
		nil)
	if err := whoami.Run(); err != nil {
		log.Println("whoami error", whoami.GetStdErr())
	}
	log.Println("whoami ->", whoami.GetStdOut())
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
