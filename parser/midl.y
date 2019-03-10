%{
package parser
import (
	"github.com/jd3nn1s/gomidl/ast"
	"github.com/jd3nn1s/gomidl/scanner"
)
%}

%union {
importNode *ast.ImportNode
interfaceNode *ast.InterfaceNode
interfaceNodeList []*ast.InterfaceNode
attributeNode *ast.AttributeNode
attributeNodeList []*ast.AttributeNode
paramAttrNode *ast.ParamAttrNode
paramAttrNodeList []*ast.ParamAttrNode
paramNode *ast.ParamNode
paramNodeList []*ast.ParamNode
methodNode *ast.MethodNode
methodNodeList []*ast.MethodNode
enumNode *ast.EnumNode
enumValueNode *ast.EnumValueNode
enumValueNodeList []*ast.EnumValueNode
typedefNode *ast.TypedefNode
libraryNode *ast.LibraryNode
importLibNode *ast.ImportLibNode
moduleConstantNode *ast.ModuleConstantNode
structNode *ast.StructNode
structFieldNode *ast.StructFieldNode
structFieldNodeList []*ast.StructFieldNode
coClassNode *ast.CoClassNode

int int
str string
lstr []string
node interface{}
nodes []interface{}
bool bool
intf interface{}
}

%token INTERFACE IDENT IMPORT STRING CPP_QUOTE MIDL_PRAGMA NUM ENUM TYPEDEF LIBRARY IMPORTLIB MODULE STRUCT COCLASS DEFAULT
// interface attributes
%token POINTER_DEFAULT OBJECT UUID OLEAUTOMATION LOCAL HELPSTRING
// library attributes
%token LCID VERSION
// variables
%token LONG CONST
// module attributes
%token DLLNAME
// method attributes
%token PROPGET PROPPUT
// parameter attributes
%token IN OUT MAX_IS RETVAL SIZE_IS ANNOTATION ATTR_STRING UNIQUE IID_IS
// typedef attributes
%token V1_ENUM

%type <importNode> importFiles
%type <interfaceNode> interface
%type <interfaceNodeList> interfaceList

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

%type <coClassNode> coclass

%type <lstr> stringListLoop
%type <str> STRING IDENT NUM LONG UNIQUE
%type <bool> array
%type <str> parentInterface enumVal paramType sizeParams sizeParam pointerType

%type <intf> cppQuote
%type <node> entry libraryEntry
%type <nodes> complete entryList libraryEntryList

%type <int> optionalPointer


%nonassoc ENUM
%nonassoc IDENT

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

library: optionalAttributeList LIBRARY IDENT '{' libraryEntryList '}' optionalSemicolon
	{
		$$ = &ast.LibraryNode{
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
		$$ = &ast.ImportLibNode{
			Filename: $3,
		}
	}
	| module
	{
		$$ = &ast.ModuleNode{
		}
	}
	| coclass
	{ $$ = $1 }

//// coclass

coclass: optionalAttributeList COCLASS IDENT '{' interfaceList '}'
{
	$$ = &ast.CoClassNode{
		Name: $3,
		Attributes: $1,
		Interfaces: $5,
	}
}

interfaceList:
	optionalAttributeList INTERFACE IDENT ';'
	{
		$$ = []*ast.InterfaceNode{{
			Name: $3,
		}}
	}
	| interfaceList optionalAttributeList INTERFACE IDENT ';'
	{
		$$ = append($1, &ast.InterfaceNode{
			Name: $4,
		})
	}
//// module

module: optionalAttributeList MODULE IDENT '{' moduleEntryList '}' ';'
	| optionalAttributeList MODULE IDENT '{' moduleEntryList '}'

moduleEntryList: moduleEntry
	| moduleEntryList moduleEntry

moduleEntry: CONST LONG IDENT '=' NUM ';'
	{
		$$ = &ast.ModuleConstantNode{
			Name: $3,
			Val: $5,
		}
	}

//// midl pragma

midlPragma: MIDL_PRAGMA IDENT '(' IDENT ':' NUM ')'

//// struct


struct: optionalAttributeList TYPEDEF STRUCT IDENT '{' structEntryList '}' IDENT ';'
{
	$$ = &ast.StructNode{
		Name: $8,
		Fields: $6,
	}
}

structEntryList: /* empty */

	{
		$$ = []*ast.StructFieldNode{}
	}
	| structEntry
	{
		$$ = []*ast.StructFieldNode{$1}
	}
	| structEntryList structEntry
	{
		$$ = append($1, $2)
	}

structEntry: optionalParamAttrs paramType optionalPointer IDENT ';'
	{
		$$ = &ast.StructFieldNode{
			Type: $2,
			Name: $4,
			Attributes: $1,
		}
	}

//// enum

enum: ENUM IDENT '{' enumEntryList '}' ';'
	{
		$$ = &ast.EnumNode{
			Name: $2,
			Values: $4,
		}
	}
	| optionalAttributeList TYPEDEF ENUM IDENT '{' enumEntryList '}' IDENT ';'
	{
		$$ = &ast.EnumNode{
			Name: $8,
			Values: $6,
		}
	}

enumEntryList: /* empty */
		{
			$$ = []*ast.EnumValueNode{}
		}
	| enumEntry
		{
			if $1 != nil {
				$$ = []*ast.EnumValueNode{$1}
			} else {
				$$ = []*ast.EnumValueNode{}
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
	| enumEntryList ','

enumEntry: IDENT '=' enumVal
	{
		$$ = &ast.EnumValueNode{
			Name: $1,
			Val: $3,
		}
	}
	| IDENT
	{
		$$ = &ast.EnumValueNode{
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
	{ $$ = &ast.ImportNode{Files: $2} }

stringListLoop: STRING
		{ $$ = []string{$1} }
	| stringListLoop ',' STRING
		{ $$ = append($1, $3) }

//// typedefs

typedef: optionalAttributeList TYPEDEF paramType optionalPointer IDENT ';'
	{
		$$ = &ast.TypedefNode{
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
		$$ = &ast.InterfaceNode{
			Name: $3,
			ParentName: $4,
			Attributes: $1,
			Methods: $5,
		}
	}
	| optionalAttributeList INTERFACE IDENT parentInterface methodBlock
	{
		$$ = &ast.InterfaceNode{
			Name: $3,
			ParentName: $4,
			Attributes: $1,
			Methods: $5,
		}
	}

//// interface attributes

optionalAttributeList: /* empty */
		{ $$ = []*ast.AttributeNode{} }
	| '[' attributeList ']'
		{ $$ = $2 }

attributeList: attribute
		{
			if $1 != nil {
				$$ = []*ast.AttributeNode{$1}
			} else {
				$$ = []*ast.AttributeNode{}
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
		{ $$ = &ast.AttributeNode{Type: scanner.OBJECT} }
	| UUID '(' IDENT ')'
		{ $$ = &ast.AttributeNode{Type: scanner.UUID, Val: $3} }
	| POINTER_DEFAULT '(' pointerType ')'
		{ $$ = &ast.AttributeNode{Type: scanner.POINTER_DEFAULT, Val: $3} }
	| OLEAUTOMATION
		{ $$ = &ast.AttributeNode{Type: scanner.OLEAUTOMATION} }
	| LCID '(' NUM ')'
		{ $$ = &ast.AttributeNode{Type: scanner.LCID, Val: $3} }
	| VERSION '(' IDENT ')'
		{ $$ = &ast.AttributeNode{Type: scanner.VERSION, Val: $3} }
	| DLLNAME '(' STRING ')'
		{ $$ = &ast.AttributeNode{Type: scanner.DLLNAME, Val: $3} }
	| V1_ENUM
		{ $$ = &ast.AttributeNode{Type: scanner.V1_ENUM} }
	| LOCAL
		{ $$ = &ast.AttributeNode{Type: scanner.LOCAL} }
	| HELPSTRING '(' STRING ')'
		{ $$ = &ast.AttributeNode{Type: scanner.HELPSTRING, Val: $3} }
	| DEFAULT
		{ $$ = &ast.AttributeNode{Type: scanner.DEFAULT} }

pointerType: UNIQUE
	{ $$ = $1 }
	| IDENT
	{ $$ = $1 }

//// interface methods
methodBlock: /* empty */
		{ $$ = []*ast.MethodNode{} }
	| '{' '}'
		{ $$ = []*ast.MethodNode{} }
	| '{' methodList '}'
		{ $$ = $2 }

methodList: method ';'
	{ $$ = []*ast.MethodNode{$1} }
	| methodList method ';'
	{ $$ = append($1, $2) }

method: optionalMethodAttrs IDENT IDENT '(' paramList ')'
	{
		$$ = &ast.MethodNode{
			ReturnType: $2,
			Name: $3,
			Params: $5,
		}
	}

optionalMethodAttrs: /* empty */
		{ $$ = []*ast.AttributeNode{} }
	| '[' methodAttrList ']'
		{ $$ = $2 }

methodAttrList: methodAttr
		{
			if $1 != nil {
				$$ = []*ast.AttributeNode{$1}
			} else {
				$$ = []*ast.AttributeNode{}
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
		{ $$ = &ast.AttributeNode{Type: scanner.PROPGET} }
	| PROPPUT
		{ $$ = &ast.AttributeNode{Type: scanner.PROPPUT} }


//// method parameters

paramList: /* empty */
	{
		$$ = nil
	}
	|param
	{
		$$ = []*ast.ParamNode{$1}
	}
	| paramList ',' param
	{
		$$ = append($1, $3)
	}

optionalParamAttrs: /* empty */
	{ $$ = nil }
	| '[' paramAttrList ']'
	{ $$ = $2 }

param: optionalParamAttrs const paramType const optionalPointer IDENT array
	{
		$$ = &ast.ParamNode{
			Attributes: $1,
			Type: $3,
			Indirections: $5,
			Name: $6,
			Array: $7,
		}
	}

paramType: LONG
	{ $$ = $1 }
	| IDENT
	{ $$ = $1 }
	| IDENT '(' IDENT ')'
	{ $$ = $1 + "(" + $3 + ")" }
	| ENUM IDENT
	{ $$ = "enum" + $2 }

const: /* empty */
	| CONST

array: /* empty */
	{ $$ = false }
	| '[' ']'
	{ $$ = true }

paramAttrList: paramAttr
		{ $$ = []*ast.ParamAttrNode{$1} }
	| paramAttrList ',' paramAttr
		{ $$ = append($1, $3) }

paramAttr: IN
		{ $$ = &ast.ParamAttrNode{Type: scanner.IN} }
	| OUT
		{ $$ = &ast.ParamAttrNode{Type: scanner.OUT} }
	| MAX_IS '(' IDENT ')'
		{ $$ = &ast.ParamAttrNode{Type: scanner.MAX_IS, Val:$3} }
	| RETVAL
		{ $$ = &ast.ParamAttrNode{Type: scanner.RETVAL} }
	| SIZE_IS '(' sizeParams ')'
		{ $$ = &ast.ParamAttrNode{Type: scanner.SIZE_IS, Val: $3} }
	| ANNOTATION '(' STRING ')'
		{ $$ = &ast.ParamAttrNode{Type: scanner.ANNOTATION, Val: $3} }
	| ATTR_STRING
		{ $$ = &ast.ParamAttrNode{Type: scanner.STRING} }
	| UNIQUE
		{ $$ = &ast.ParamAttrNode{Type: scanner.UNIQUE} }
	| IID_IS '(' IDENT ')'
		{ $$ = &ast.ParamAttrNode{Type: scanner.IDENT, Val: $3} }

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

optionalSemicolon: /* empty */
	| ';'
