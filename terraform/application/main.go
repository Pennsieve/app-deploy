package main

import (
	"os"
	"os/exec"
	"strings"

	"log/slog"
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	integrationID := os.Getenv("INTEGRATION_ID")
	inputDir := "/service/data"
	outDir := "/mnt"

	if os.Getenv("INPUT_DIR") != "" {
		inputDir = os.Getenv("INPUT_DIR")
	}
	if os.Getenv("OUT_DIR") != "" {
		outDir = os.Getenv("OUT_DIR")
	}

	// TODO: create input and output directories -> /mnt/input<integrationID> and /mnt/output<integrationID>

	// run pipeline
	cmd := exec.Command("nextflow", "run", "/service/main.nf", "-ansi-log", "false", "--integration", integrationID, "--inputDir", inputDir, "--outDir", outDir)
	cmd.Dir = "/service"
	var out strings.Builder
	var stderr strings.Builder
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		logger.Error(err.Error(),
			slog.String("error", stderr.String()))
	}

	logger.Info("pipeline output",
		slog.String("output", out.String()))

	logger.Info("Processing complete")
}
