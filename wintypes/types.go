package wintypes

import "github.com/go-ole/go-ole"

type HWND uintptr
type HBITMAP uintptr

type PROPERTYKEY struct {
	fmtid ole.GUID
	pid   int32
}
