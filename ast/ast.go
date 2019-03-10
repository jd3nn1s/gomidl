package ast

import "github.com/jd3nn1s/gomidl/scanner"

type ImportNode struct {
	Files []string
}

type AttributeNode struct {
	Val  string
	Type scanner.TokenType
}

type ParamAttrNode struct {
	Val  string
	Type scanner.TokenType
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
	Name   string
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
	Name   string
	Fields []*StructFieldNode
}

type StructFieldNode struct {
	Type       string
	Name       string
	Attributes []*ParamAttrNode
}

type CoClassNode struct {
	Name       string
	Attributes []*AttributeNode
	Interfaces []*InterfaceNode
}
