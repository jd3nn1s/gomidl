//go:generate goyacc -l -o midl.go ../midl.y

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
	fmt.Printf("%#v\n", Parse(f))
}

func (f *mlex) Lex(lval *yySymType) int {
	if !f.s.Read() {
		if f.s.Error() != nil && f.s.Error() != io.EOF {
			log.Fatal(f.s.Error())
		}
		return 0
	}

	log.Println(f.s.LastToken())

	switch t := f.s.LastToken(); {
	case t.Type == go_midl.IMPORT:
		return IMPORT
	case t.Type == go_midl.STRING:
		lval.str = t.Val
		return STRING
	case t.Type == go_midl.COMMA:
		return ','
	case t.Type == go_midl.SEMICOLON:
		return ';'
	case t.Type == go_midl.COLON:
		return ':'
	case t.Type == go_midl.LPAREN:
		return '('
	case t.Type == go_midl.RPAREN:
		return ')'
	case t.Type == go_midl.LBRACE:
		return '{'
	case t.Type == go_midl.RBRACE:
		return '}'
	case t.Type == go_midl.LBRACK:
		return '['
	case t.Type == go_midl.RBRACK:
		return ']'
	case t.Type == go_midl.PTR:
		return '*'
	case t.Type == go_midl.EQUALS:
		return '='
	case t.Type == go_midl.IDENT:
		lval.str = t.Val
		return IDENT
	case t.Type == go_midl.INTERFACE:
		return INTERFACE
	case t.Type == go_midl.OBJECT:
		return OBJECT
	case t.Type == go_midl.LCID:
		return LCID
	case t.Type == go_midl.VERSION:
		return VERSION
	case t.Type == go_midl.UUID:
		return UUID
	case t.Type == go_midl.POINTER_DEFAULT:
		return POINTER_DEFAULT
	case t.Type == go_midl.OLEAUTOMATION:
		return OLEAUTOMATION
	case t.Type == go_midl.V1_ENUM:
		return V1_ENUM
	case t.Type == go_midl.MAX_IS:
		return MAX_IS
	case t.Type == go_midl.IN:
		return IN
	case t.Type == go_midl.OUT:
		return OUT
	case t.Type == go_midl.PROPGET:
		return PROPGET
	case t.Type == go_midl.PROPPUT:
		return PROPPUT
	case t.Type == go_midl.ANNOTATION:
		return ANNOTATION
	case t.Type == go_midl.LOCAL:
		return LOCAL
	case t.Type == go_midl.CPP_QUOTE:
		return CPP_QUOTE
	case t.Type == go_midl.ENUM:
		return ENUM
	case t.Type == go_midl.STRUCT:
		return STRUCT
	case t.Type == go_midl.TYPEDEF:
		return TYPEDEF
	case t.Type == go_midl.LIBRARY:
		return LIBRARY
	case t.Type == go_midl.IMPORTLIB:
		return IMPORTLIB
	case t.Type == go_midl.MIDL_PRAGMA:
		return MIDL_PRAGMA
	case t.Type == go_midl.MODULE:
		return MODULE
	case t.Type == go_midl.DLLNAME:
		return DLLNAME
	case t.Type == go_midl.CONST:
		return CONST
	case t.Type == go_midl.RETVAL:
		return RETVAL
	case t.Type == go_midl.SIZE_IS:
		return SIZE_IS
	case t.Type == go_midl.UNIQUE:
		return UNIQUE
	case t.Type == go_midl.ATTR_STRING:
		return ATTR_STRING
	case t.Type == go_midl.IID_IS:
		return IID_IS
	case t.Type == go_midl.HELPSTRING:
		return HELPSTRING
	case t.Type == go_midl.DEFAULT:
		return DEFAULT
	case t.Type == go_midl.COCLASS:
		return COCLASS
	case t.Type == go_midl.LONG:
		return LONG
	case t.Type == go_midl.NUM:
		return NUM
	case t.Type == go_midl.B_OR:
		return '|'
	default:
		log.Fatalln("unknown token", t)
	}
	yyErrorVerbose = true
	return 0
}

type mlex struct {
	s      *go_midl.Scanner
	result []interface{}
}

func (f *mlex) Error(s string) {
	fmt.Printf("syntax error: %s\n", s)
}

func Parse(r io.Reader) []interface{} {
	s := go_midl.NewScanner(r)
	m := &mlex{s, nil}
	yyParse(m)
	return m.result
}

func setResult(l yyLexer, nodes []interface{}) {
	l.(*mlex).result = nodes
}
