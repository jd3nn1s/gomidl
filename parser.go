//go:generate goyacc -l -o main2/midl.go midl.y

package go_midl

import (
	"fmt"
	"log"
)

type ParserStep int

const (
	ROOT ParserStep = iota
	ATTRIBUTES
	STEP_INTERFACE
)

type Parser struct {
	step ParserStep
	pos  int
	ts   []Token
}

type ImportNode struct {
	Files []string
}

type AttributeNode struct {
	Val  string
	Type TokenType
}

type ParamAttrNode struct {
	Val  string
	Type TokenType
}

type ParamNode struct {
	Attributes   []*ParamAttrNode
	Type         string
	Indirections int
	Name         string
	Array        bool
}

type InterfaceNode struct {
	Name       string
	ParentName string
	Attributes []*AttributeNode
	Methods    []*MethodNode
}

type MethodNode struct {
	Name       string
	ReturnType string
	Params     []*ParamNode
}

type EnumNode struct {
	Name string
	Values []*EnumValueNode
}

type EnumValueNode struct {
	Name string
	Val  string
}

type TypedefNode struct {
	Name        string
	Type        string
	Indirection int
	Attributes  []*AttributeNode
}

type LibraryNode struct {
	Name       string
	Attributes []*AttributeNode
	Nodes      []interface{}
}

type ImportLibNode struct {
	Filename string
}

type ModuleConstantNode struct {
	Name string
	Val  string
}

type ModuleNode struct {
	Name  string
	Nodes []interface{}
}

type StructNode struct {
	Name string
	Fields []*StructFieldNode
}

type StructFieldNode struct {
	Type string
	Name string
	Attributes []*ParamAttrNode
}

func (p *Parser) Parse(ts []Token) error {
	p.ts = ts
	for p.pos < len(ts) {
		var node interface{}

		if p.step == ROOT {
			switch t := p.next(); {
			case t.Type == IMPORT:
				importNode := p.importNode(t)
				node = importNode
			case t.Type == LBRACK:
				p.step = ATTRIBUTES
			default:
				return fmt.Errorf("unexpected token in root scope: %v", ts[p.pos])
			}
		} else if p.step == ATTRIBUTES {
			node = p.objAttributes()
			p.mustFindNext(RBRACK)
			p.step = STEP_INTERFACE
		}
		if node != nil {
			log.Printf("node: %#v\n", node)
		}
	}
	return nil
}

func (p *Parser) next() Token {
	if p.pos > len(p.ts) {
		log.Fatalln("unexpected end of file")
	}
	p.pos++
	return p.ts[p.pos-1]
}

func (p *Parser) peek() Token {
	if p.pos > len(p.ts) {
		log.Fatalln("unexpected end of file")
	}
	return p.ts[p.pos]
}

func (p *Parser) mustFindNext(tt TokenType) Token {
	t := p.next()
	if t.Type != tt {
		log.Fatalln("expected token type", tt, "but found", t)
	}
	return t
}

func (p *Parser) objAttributes() []AttributeNode {
	nodes := make([]AttributeNode, 0)
	for {
		node := AttributeNode{}
		t := p.next()
		if t.Type == RBRACK {
			return nodes
		} else if t.Type <= attr_beg || t.Type >= attr_end {
			log.Fatalf("next token not an attribute type: %v", t)
		}

		node.Type = t.Type
		t = p.peek()
		if t.Type == LPAREN {
			p.next()
			t = p.mustFindNext(IDENT)
			node.Val = t.Val
			p.mustFindNext(RPAREN)
			nodes = append(nodes, node)
		}
		t = p.peek()
		if t.Type != COMMA {
			break
		}
		p.next()
	}
	return nodes
}

func (p *Parser) importNode(t Token) ImportNode {
	if t.Type != IMPORT {
		log.Fatalln("importNode can only process import tokens")
	}
	imp := ImportNode{
		Files: make([]string, 0),
	}
	for {
		t = p.next()
		if t.Type == SEMICOLON {
			break
		} else if t.Type == COMMA {
			continue
		} else if t.Type != STRING {
			log.Fatalf("import expecting string, found %s", t)
		}
		imp.Files = append(imp.Files, t.Val)
	}
	if len(imp.Files) == 0 {
		log.Fatalf("import statement should specify file or files to import")
	}
	return imp
}
