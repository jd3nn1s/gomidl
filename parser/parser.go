//go:generate goyacc -l -o midl.go midl.y

package parser

import (
	"fmt"
	"io"
	"log"

	"github.com/jd3nn1s/gomidl/scanner"
)

var scannerToParserMap = map[scanner.TokenType]int{
	scanner.STRING: STRING,
	scanner.IDENT:  IDENT,

	scanner.COMMA:     ',',
	scanner.SEMICOLON: ';',
	scanner.COLON:     ':',
	scanner.LPAREN:    '(',
	scanner.RPAREN:    ')',
	scanner.LBRACE:    '{',
	scanner.RBRACE:    '}',
	scanner.LBRACK:    '[',
	scanner.RBRACK:    ']',
	scanner.PLUS:      '+',
	scanner.DASH:      '-',
	scanner.PTR:       '*',
	scanner.DIV:       '/',
	scanner.EQUALS:    '=',
	scanner.B_OR:      '|',

	scanner.IMPORT:          IMPORT,
	scanner.INTERFACE:       INTERFACE,
	scanner.OBJECT:          OBJECT,
	scanner.LCID:            LCID,
	scanner.VERSION:         VERSION,
	scanner.UUID:            UUID,
	scanner.POINTER_DEFAULT: POINTER_DEFAULT,
	scanner.OLEAUTOMATION:   OLEAUTOMATION,
	scanner.V1_ENUM:         V1_ENUM,
	scanner.MAX_IS:          MAX_IS,
	scanner.IN:              IN,
	scanner.OUT:             OUT,
	scanner.PROPGET:         PROPGET,
	scanner.PROPPUT:         PROPPUT,
	scanner.ENTRY:           ENTRY,
	scanner.ANNOTATION:      ANNOTATION,
	scanner.LOCAL:           LOCAL,
	scanner.CPP_QUOTE:       CPP_QUOTE,
	scanner.ENUM:            ENUM,
	scanner.STRUCT:          STRUCT,
	scanner.TYPEDEF:         TYPEDEF,
	scanner.LIBRARY:         LIBRARY,
	scanner.IMPORTLIB:       IMPORTLIB,
	scanner.MIDL_PRAGMA:     MIDL_PRAGMA,
	scanner.MODULE:          MODULE,
	scanner.DLLNAME:         DLLNAME,
	scanner.CONST:           CONST,
	scanner.RETVAL:          RETVAL,
	scanner.SIZE_IS:         SIZE_IS,
	scanner.UNIQUE:          UNIQUE,
	scanner.ATTR_STRING:     ATTR_STRING,
	scanner.IID_IS:          IID_IS,
	scanner.HELPSTRING:      HELPSTRING,
	scanner.DEFAULT:         DEFAULT,
	scanner.NONCREATABLE:    NONCREATABLE,
	scanner.COCLASS:         COCLASS,
	scanner.LONG:            LONG,
	scanner.NUM:             NUM,
}

func (f *mlex) Lex(lval *yySymType) int {
	if !f.s.Read() {
		if f.s.Error() != nil && f.s.Error() != io.EOF {
			log.Fatal(f.s.Error())
		}
		return 0
	}

	log.Println(f.s.LastToken())

	t := f.s.LastToken().Type
	parserType, ok := scannerToParserMap[t]
	if !ok {
		log.Fatalln("unknown token", t)
	}

	lval.str = f.s.LastToken().Val

	return parserType
}

type mlex struct {
	s      *scanner.Scanner
	result []interface{}
}

func (f *mlex) Error(s string) {
	fmt.Printf("syntax error: %s\n", s)
}

func Parse(r io.Reader) []interface{} {
	s := scanner.NewScanner(r)
	m := &mlex{s, nil}
	yyParse(m)
	return m.result
}

func setResult(l yyLexer, nodes []interface{}) {
	l.(*mlex).result = nodes
}
