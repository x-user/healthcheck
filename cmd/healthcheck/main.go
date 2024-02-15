package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: healthcheck <url>")
		os.Exit(1)
	}

	url := os.Args[1]
	log.Println("Healthcheck:", url)
	if _, err := http.Get(url); err != nil {
		log.Fatalln("Healthcheck failed:", err)
	}
}
