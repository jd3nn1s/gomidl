package main

import (
	"fmt"
	"github.com/jd3nn1s/gomidl/parser"
	"log"
	"os"
)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		log.Fatalf("could not open file: %v", err)
	}
	defer f.Close()

	fmt.Printf("%#v\n", parser.Parse(f))
}
