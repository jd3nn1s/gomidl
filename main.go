package main

import (
	"github.com/jd3nn1s/gomidl/backend"
	"github.com/jd3nn1s/gomidl/parser"
	"log"
	"os"
)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		log.Fatalf("could not open input file: %v", err)
	}
	defer f.Close()

	out, err := os.OpenFile(os.Args[2], os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalf("could not open output file: %v", err)
	}
	defer out.Close()

	backend.Generate(parser.Parse(f), out)
}
