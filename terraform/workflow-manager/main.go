package main

import (
	"bytes"
	"io"
	"log"
	"log/slog"
	"net/http"
	"os"
)

func main() {
	programLevel := new(slog.LevelVar)
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel}))
	slog.SetDefault(logger)

	log.Println("Welcome to the WorkflowManager")
	log.Println("Starting pipeline")

	// // run pipeline
	// cmd := exec.Command("nextflow", "run", "./workflows/pennsieve.nf", "-ansi-log", "false")
	// cmd.Dir = "/service"
	// var stdout strings.Builder
	// var stderr strings.Builder
	// cmd.Stdout = &stdout
	// cmd.Stderr = &stderr
	// if err := cmd.Run(); err != nil {
	// 	logger.Error(err.Error(),
	// 		slog.String("error", stderr.String()))
	// }
	// log.Println(stdout.String())
	srv := &http.Server{
		Addr:    ":8081",
		Handler: NewHandler(),
	}

	log.Fatal(srv.ListenAndServe())
}

func NewHandler() http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/start", &WorkflowManagerServiceHandler{})
	return mux
}

func (dh *WorkflowManagerServiceHandler) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	_ = req.Context()
	body := req.Body
	defer body.Close()
	rw.WriteHeader(http.StatusAccepted)
	rw.Header().Set("Content-Type", "application/json")
	var b bytes.Buffer
	io.Copy(&b, body)
	log.Print(b.String())
	rw.Write(b.Bytes())
}

type WorkflowManagerServiceHandler struct {
}
