package main

import (
	"log"
	"os"
	"os/exec"
	"strings"

	"log/slog"
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	inputDir := os.Getenv("INPUT_DIR")
	outputDir := os.Getenv("OUTPUT_DIR")

	log.Println("Starting pipeline")
	// run pipeline
	cmd := exec.Command("nextflow", "run", "/service/main.nf", "-ansi-log", "false", "--inputDir", inputDir, "--outputDir", outputDir)
	cmd.Dir = "/service"
	var out strings.Builder
	var stderr strings.Builder
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		logger.Error(err.Error(),
			slog.String("error", stderr.String()))
	}
	log.Println(out.String())

	// run pipeline
	ls := exec.Command("ls", "-alh")
	ls.Dir = outputDir
	var out2 strings.Builder
	var stderr2 strings.Builder
	ls.Stdout = &out2
	ls.Stderr = &stderr2
	if err := ls.Run(); err != nil {
		logger.Error(err.Error(),
			slog.String("error", stderr2.String()))
	}
	log.Println(out2.String())

	logger.Info("Processing complete")
}
