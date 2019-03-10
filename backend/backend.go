package backend

import (
	"fmt"
	"github.com/jd3nn1s/gomidl/ast"
	"io"
	"log"
)

func Generate(nodes []interface{}, writer io.Writer) {
	gen := Generator{}
	for _, n := range nodes {
		switch v := n.(type) {
		case *ast.ImportNode:
		// ignore
		case *ast.StructNode:
			gen.genStruct(v)
		case *ast.EnumNode:
			gen.genEnum(v)
		case *ast.TypedefNode:
			gen.genTypedef(v)
		case *ast.InterfaceNode:
			gen.genInterface(v)
		case *ast.LibraryNode:
			gen.genLibrary(v)
		default:
			log.Printf("unsupported %T\n", v)
		}
	}
	gen.genPackage("testpkg")
	fmt.Fprintln(writer, string(gen.format()))
}
