package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

var CommandRunDirectory = "/service"

func main() {
	fmt.Println("Welcome to the Post-Processor")
	log.Println("Starting pennsieve agent ...")
	envVars := map[string]string{
		"PENNSIEVE_API_HOST":   os.Getenv("PENNSIEVE_API_HOST"),
		"PENNSIEVE_API_KEY":    os.Getenv("PENNSIEVE_API_KEY"),
		"PENNSIEVE_API_SECRET": os.Getenv("PENNSIEVE_API_SECRET"),
		"HOME":                 os.Getenv("HOME"),
	}
	log.Println("contents of storage ...")
	ls := NewExecution(exec.Command("ls", "-alh", "/mnt/efs"),
		CommandRunDirectory,
		nil)
	if err := ls.Run(); err != nil {
		log.Println("ls", ls.GetStdErr())
	}
	log.Println("ls -> ", ls.GetStdOut())
	agent := NewExecution(exec.Command("pennsieve", "agent"),
		CommandRunDirectory,
		envVars)
	if err := agent.Run(); err != nil {
		log.Println("pennsieve error", agent.GetStdErr())
	}
	log.Println("agent -> ", agent.GetStdOut())
	log.Println("Running whoami ...")
	whoami := NewExecution(exec.Command("pennsieve", "whoami"),
		CommandRunDirectory,
		envVars)
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
