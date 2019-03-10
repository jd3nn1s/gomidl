package scanner

import (
	"fmt"
	"text/scanner"
)

type TokenType int

const (
	ILLEGAL TokenType = iota
	EOF
	COMMENT

	literal_beg
	IDENT
	STRING
	NUM
	literal_end

	operators_beg
	LPAREN // (
	RPAREN // )
	LBRACK // [
	RBRACK // ]
	LBRACE // {
	RBRACE // }

	COMMA     // ,
	COLON     // :
	SEMICOLON // ;
	DASH      // -
	PTR       // *
	EQUALS    // =
	B_OR      // |
	operators_end

	keyword_beg
	IMPORT
	INTERFACE
	CPP_QUOTE
	MIDL_PRAGMA
	ENUM
	COCLASS
	TYPEDEF
	LIBRARY
	IMPORTLIB
	MODULE
	CONST
	LONG
	STRUCT
	HELPSTRING
	keyword_end

	attr_beg
	UUID
	OBJECT
	POINTER_DEFAULT
	LCID
	VERSION
	DLLNAME
	PROPGET
	PROPPUT
	RETVAL
	SIZE_IS
	OLEAUTOMATION
	LOCAL
	ATTR_STRING
	DEFAULT

	V1_ENUM
	attr_end

	param_attr_beg
	IN
	OUT
	ANNOTATION
	MAX_IS
	UNIQUE
	IID_IS
	param_attr_end
)

var tokenEnumMap = map[TokenType]string{
	IDENT:  "IDENT",
	STRING: "STRING",
	NUM:    "NUM",

	IMPORT:          "import",
	CPP_QUOTE:       "cpp_quote",
	OBJECT:          "object",
	UUID:            "uuid",
	DLLNAME:         "dllname",
	POINTER_DEFAULT: "pointer_default",
	LCID:            "lcid",
	VERSION:         "version",
	INTERFACE:       "interface",
	ENUM:            "enum",
	STRUCT:          "struct",
	MIDL_PRAGMA:     "midl_pragma",
	TYPEDEF:         "typedef",
	V1_ENUM:         "v1_enum",
	LIBRARY:         "library",
	IMPORTLIB:       "importlib",
	PROPGET:         "propget",
	PROPPUT:         "propput",
	OLEAUTOMATION:   "oleautomation",
	SIZE_IS:         "size_is",
	RETVAL:          "retval",
	ANNOTATION:      "annotation",
	LOCAL:           "local",
	UNIQUE:          "unique",
	MODULE:          "module",
	CONST:           "const",
	LONG:            "long",
	ATTR_STRING:     "string",
	COCLASS:         "coclass",
	IID_IS:          "iid_is",
	HELPSTRING:      "helpstring",
	DEFAULT:         "default",

	IN:     "in",
	OUT:    "out",
	MAX_IS: "max_is",

	LPAREN: "(",
	RPAREN: ")",
	LBRACK: "[",
	RBRACK: "]",
	LBRACE: "{",
	RBRACE: "}",

	COMMA:     ",",
	COLON:     ":",
	SEMICOLON: ";",
	DASH:      "-",
	PTR:       "*",
	EQUALS:    "=",
	B_OR:      "|",
}

type Token struct {
	Type     TokenType
	Position scanner.Position
	Val      string
}

func (t Token) String() string {
	return fmt.Sprintf("%s\t\t[%s]",
		tokenEnumMap[t.Type],
		t.Val)
}

var tokenStringMap map[string]TokenType

func init() {
	tokenStringMap = make(map[string]TokenType)
	for i := keyword_beg + 1; i < keyword_end; i++ {
		tokenStringMap[tokenEnumMap[i]] = i
	}
	for i := attr_beg + 1; i < attr_end; i++ {
		tokenStringMap[tokenEnumMap[i]] = i
	}
	for i := param_attr_beg + 1; i < param_attr_end; i++ {
		tokenStringMap[tokenEnumMap[i]] = i
	}
}

func keyword(s string) TokenType {
	if v, ok := tokenStringMap[s]; ok {
		return v
	}
	return ILLEGAL
}
