%{
package main
import (
	"go-midl"
)
%}

%union {
importNode *go_midl.ImportNode
interfaceNode *go_midl.InterfaceNode
interfaceNodeList []*go_midl.InterfaceNode
attributeNode *go_midl.AttributeNode
attributeNodeList []*go_midl.AttributeNode
paramAttrNode *go_midl.ParamAttrNode
paramAttrNodeList []*go_midl.ParamAttrNode
paramNode *go_midl.ParamNode
paramNodeList []*go_midl.ParamNode
methodNode *go_midl.MethodNode
methodNodeList []*go_midl.MethodNode
enumNode *go_midl.EnumNode
enumValueNode *go_midl.EnumValueNode
enumValueNodeList []*go_midl.EnumValueNode
typedefNode *go_midl.TypedefNode
libraryNode *go_midl.LibraryNode
importLibNode *go_midl.ImportLibNode
moduleConstantNode *go_midl.ModuleConstantNode
structNode *go_midl.StructNode
structFieldNode *go_midl.StructFieldNode
structFieldNodeList []*go_midl.StructFieldNode

int int
str string
lstr []string
node interface{}
nodes []interface{}
bool bool
intf interface{}
}

%token INTERFACE IDENT IMPORT STRING CPP_QUOTE MIDL_PRAGMA NUM ENUM TYPEDEF LIBRARY IMPORTLIB MODULE STRUCT
// interface attributes
%token POINTER_DEFAULT OBJECT UUID OLEAUTOMATION
// library attributes
%token LCID VERSION
// variables
%token LONG CONST
// module attributes
%token DLLNAME
// method attributes
%token PROPGET PROPPUT
// parameter attributes
%token IN OUT MAX_IS RETVAL SIZE_IS
// typedef attributes
%token V1_ENUM

%type <importNode> importFiles
%type <interfaceNode> interface

%type <attributeNode> attribute methodAttr
%type <attributeNodeList> optionalAttributeList attributeList optionalMethodAttrs methodAttrList

%type <methodNode> method
%type <methodNodeList> methodList methodBlock

%type <paramNode> param
%type <paramNodeList> paramList

%type <paramAttrNode> paramAttr
%type <paramAttrNodeList> paramAttrList optionalParamAttrs

%type <enumNode> enum
%type <enumValueNodeList> enumEntryList
%type <enumValueNode> enumEntry

%type <typedefNode> typedef

%type <libraryNode> library

%type <structNode> struct
%type <structFieldNode> structEntry
%type <structFieldNodeList> structEntryList

%type <moduleConstantNode> moduleEntry

%type <lstr> stringListLoop
%type <str> STRING IDENT NUM LONG
%type <bool> array
%type <str> parentInterface enumVal paramType sizeParams sizeParam

%type <intf> cppQuote
%type <node> entry libraryEntry
%type <nodes> complete entryList libraryEntryList

%type <int> optionalPointer

%%

complete: entryList
	{ setResult(yylex, $$) }

entryList: entry
	{
		if $1 != nil {
			$$ = []interface{}{$1}
		} else {
			$$ = []interface{}{}
		}
	}
	| entryList entry
	{ if $2 != nil {$$ = append($1, $2)} }

entry: cppQuote
	{ $$ = $1 }
	| importFiles
	{ $$ = $1 }
	| enum
	{ $$ = $1 }
	| interface
	{ $$ = $1 }
	| midlPragma
	{ $$ = nil }
	| typedef
	{ $$ = $1 }
	| library
	{ $$ = $1 }
	| struct
	{ $$ = $1 }

//// cpp_quote

cppQuote: CPP_QUOTE '(' STRING ')'
	{ $$ = nil }

//// library

library: optionalAttributeList LIBRARY IDENT '{' libraryEntryList '}'
	{
		$$ = &go_midl.LibraryNode{
			Name: $3,
			Attributes: $1,
			Nodes: $5,
		}
	}

libraryEntryList: libraryEntry
	{
		if $1 != nil {
			$$ = []interface{}{interface{}($1)}
		} else {
			$$ = []interface{}{}
		}
	}
	| libraryEntryList libraryEntry
	{
		if $2 != nil {
			$$ = append($1, $2)
		}
	}

libraryEntry: interface
	{ $$ = $1 }
	| IMPORTLIB '(' STRING ')' ';'
	{
		$$ = &go_midl.ImportLibNode{
			Filename: $3,
		}
	}
	| module
	{
		$$ = &go_midl.ModuleNode{
		}
	}

//// module

module: optionalAttributeList MODULE IDENT '{' moduleEntryList '}' ';'
	| optionalAttributeList MODULE IDENT '{' moduleEntryList '}'

moduleEntryList: moduleEntry
	| moduleEntryList moduleEntry

moduleEntry: CONST LONG IDENT '=' NUM ';'
	{
		$$ = &go_midl.ModuleConstantNode{
			Name: $3,
			Val: $5,
		}
	}

//// midl pragma

midlPragma: MIDL_PRAGMA IDENT '(' IDENT ':' NUM ')'

//// struct

struct: TYPEDEF STRUCT IDENT '{' structEntryList '}' IDENT ';'
{
	$$ = &go_midl.StructNode{
		Name: $7,
		Fields: $5,
	}
}

structEntryList: /* empty */
	{
		$$ = []*go_midl.StructFieldNode{}
	}
	| structEntry
	{
		$$ = []*go_midl.StructFieldNode{$1}
	}
	| structEntryList structEntry
	{
		$$ = append($1, $2)
	}

structEntry: optionalParamAttrs paramType optionalPointer IDENT ';'
	{
		$$ = &go_midl.StructFieldNode{
			Type: $2,
			Name: $4,
			Attributes: $1,
		}
	}
//// enum

enum: ENUM IDENT '{' enumEntryList '}' ';'
	{
		$$ = &go_midl.EnumNode{
			Name: $2,
			Values: $4,
		}
	}
	| optionalAttributeList TYPEDEF ENUM IDENT '{' enumEntryList '}' IDENT ';'
	{
		$$ = &go_midl.EnumNode{
			Name: $8,
			Values: $6,
		}
	}


enumEntryList: /* empty */
		{
			$$ = []*go_midl.EnumValueNode{}
		}
	| enumEntry
		{
			if $1 != nil {
				$$ = []*go_midl.EnumValueNode{$1}
			} else {
				$$ = []*go_midl.EnumValueNode{}
			}
		}
	| enumEntryList ',' enumEntry
		{
			if $3 != nil {
				$$ = append($1, $3)
			} else {
				$$ = $1
			}
		}

enumEntry: /* empty */
	{ $$ = nil }
	| IDENT '=' enumVal
	{
		$$ = &go_midl.EnumValueNode{
			Name: $1,
			Val: $3,
		}
	}
	| IDENT
	{
		$$ = &go_midl.EnumValueNode{
			Name: $1,
		}
	}

enumVal: IDENT
	{ $$ = $1 }
	| NUM
	{ $$ = $1 }
	| enumVal '|' NUM
		{ $$ = $1 + "|" + $3 }
	| enumVal '|' IDENT
		{ $$ = $1 + "|" + $3 }

//// imports

importFiles: IMPORT stringListLoop ';'
	{ $$ = &go_midl.ImportNode{Files: $2} }

stringListLoop: STRING
		{ $$ = []string{$1} }
	| stringListLoop ',' STRING
		{ $$ = append($1, $3) }

//// typedefs

typedef: optionalAttributeList TYPEDEF paramType optionalPointer IDENT ';'
	{
		$$ = &go_midl.TypedefNode{
			Type: $3,
			Indirection: $4,
			Name: $5,
			Attributes: $1,
		}
	}

//// interface

parentInterface: /* empty */
		{ $$ = "" }
	| ':' IDENT
		{ $$ = $2 }

interface: optionalAttributeList INTERFACE IDENT parentInterface methodBlock ';'
	{
		$$ = &go_midl.InterfaceNode{
			Name: $3,
			ParentName: $4,
			Attributes: $1,
			Methods: $5,
		}
	}
	| optionalAttributeList INTERFACE IDENT parentInterface methodBlock
	{
		$$ = &go_midl.InterfaceNode{
			Name: $3,
			ParentName: $4,
			Attributes: $1,
			Methods: $5,
		}
	}

//// interface attributes

optionalAttributeList: /* empty */
		{ $$ = []*go_midl.AttributeNode{} }
	| '[' attributeList ']'
		{ $$ = $2 }

attributeList: attribute
		{
			if $1 != nil {
				$$ = []*go_midl.AttributeNode{$1}
			} else {
				$$ = []*go_midl.AttributeNode{}
			}
		}
	| attributeList ',' attribute
		{
			if $3 != nil {
				$$ = append($1, $3)
			}
		}

attribute: /* empty */
		{ $$ = nil }
	| OBJECT
		{ $$ = &go_midl.AttributeNode{Type: go_midl.OBJECT} }
	| UUID '(' IDENT ')'
		{ $$ = &go_midl.AttributeNode{Type: go_midl.UUID, Val: $3} }
	| POINTER_DEFAULT '(' IDENT ')'
		{ $$ = &go_midl.AttributeNode{Type: go_midl.POINTER_DEFAULT, Val: $3} }
	| OLEAUTOMATION
		{ $$ = &go_midl.AttributeNode{Type: go_midl.OLEAUTOMATION} }
	| LCID '(' NUM ')'
		{ $$ = &go_midl.AttributeNode{Type: go_midl.LCID, Val: $3} }
	| VERSION '(' IDENT ')'
		{ $$ = &go_midl.AttributeNode{Type: go_midl.VERSION, Val: $3} }
	| DLLNAME '(' STRING ')'
		{ $$ = &go_midl.AttributeNode{Type: go_midl.DLLNAME, Val: $3} }
	| V1_ENUM
		{ $$ = &go_midl.AttributeNode{Type: go_midl.V1_ENUM} }

//// interface methods
methodBlock: /* empty */
		{ $$ = []*go_midl.MethodNode{} }
	| '{' '}'
		{ $$ = []*go_midl.MethodNode{} }
	| '{' methodList '}'
		{ $$ = $2 }

methodList: method ';'
	{ $$ = []*go_midl.MethodNode{$1} }
	| methodList method ';'
	{ $$ = append($1, $2) }

method: optionalMethodAttrs IDENT IDENT '(' paramList ')'
	{
		$$ = &go_midl.MethodNode{
			ReturnType: $2,
			Name: $3,
			Params: $5,
		}
	}

optionalMethodAttrs: /* empty */
		{ $$ = []*go_midl.AttributeNode{} }
	| '[' methodAttrList ']'
		{ $$ = $2 }

methodAttrList: methodAttr
		{
			if $1 != nil {
				$$ = []*go_midl.AttributeNode{$1}
			} else {
				$$ = []*go_midl.AttributeNode{}
			}
		}
	| methodAttrList ',' methodAttr
		{
			if $3 != nil {
				$$ = append($1, $3)
			}
		}

methodAttr: /* empty */
		{ $$ = nil }
	| PROPGET
		{ $$ = &go_midl.AttributeNode{Type: go_midl.PROPGET} }
	| PROPPUT
		{ $$ = &go_midl.AttributeNode{Type: go_midl.PROPPUT} }


//// method parameters

paramList: /* empty */
	{
		$$ = nil
	}
	|param
	{
		$$ = []*go_midl.ParamNode{$1}
	}
	| paramList ',' param
	{
		$$ = append($1, $3)
	}

optionalParamAttrs: /* empty */
	{ $$ = nil }
	| '[' paramAttrList ']'
	{ $$ = $2 }

param: '[' paramAttrList ']' paramType optionalPointer IDENT array
	{
		$$ = &go_midl.ParamNode{
			Attributes: $2,
			Type: $4,
			Indirections: $5,
			Name: $6,
			Array: $7,
		}
	}

paramType: ENUM IDENT
	{ $$ = "enum " + $2 }
	| LONG
	{ $$ = $1 }
	| IDENT
	{ $$ = $1 }
	| IDENT '(' IDENT ')'
	{ $$ = $1 + "(" + $3 + ")" }

array: /* empty */
	{ $$ = false }
	| '[' ']'
	{ $$ = true }

paramAttrList: paramAttr
		{ $$ = []*go_midl.ParamAttrNode{$1} }
	| paramAttrList ',' paramAttr
		{ $$ = append($1, $3) }

paramAttr: IN
		{ $$ = &go_midl.ParamAttrNode{Type: go_midl.IN} }
	| OUT
		{ $$ = &go_midl.ParamAttrNode{Type: go_midl.OUT} }
	| MAX_IS '(' IDENT ')'
		{ $$ = &go_midl.ParamAttrNode{Type: go_midl.MAX_IS, Val:$3} }
	| RETVAL
		{ $$ = &go_midl.ParamAttrNode{Type: go_midl.RETVAL} }
	| SIZE_IS '(' sizeParams ')'
		{ $$ = &go_midl.ParamAttrNode{Type: go_midl.SIZE_IS, Val: $3} }

sizeParams: sizeParam
	{ $$ = $1 }
	| sizeParams ',' sizeParam
	{ $$ = $1 + "," + $3 }
	| ',' sizeParam
	{ $$ = ","+$2 }

sizeParam: NUM
	{ $$ = $1 }
	| optionalPointer IDENT
	{ $$ = $2 }

optionalPointer: /* empty */
		{ $$ = 0 }
	| '*'
		{ $$ = 1 }
	| '*' '*'
		{ $$ = 2 }
	| '*' '*' '*'
		{ $$ = 3 }
