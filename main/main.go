package main

import (
	"fmt"
	"go-midl"
	"io"
	"log"
	"os"
)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		log.Fatalf("could not open file: %v", err)
	}
	defer f.Close()

	tokens := make([]go_midl.Token, 0)
	s := go_midl.NewScanner(f)
	for s.Read() {
		tokens = append(tokens, s.LastToken())
		fmt.Println(s.LastToken())
	}
	if s.Error() != nil && s.Error() != io.EOF {
		log.Fatalln(s.Error())
	}

	p := go_midl.Parser{}
	if err := p.Parse(tokens); err != nil {
		log.Fatalln("unable to parse tokens:", err)
	}
}
