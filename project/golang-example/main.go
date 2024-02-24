package main

import (
	"fmt"
	"runtime"
)

func GetVersion() string {
	return fmt.Sprintf("Go version: %s", runtime.Version())
}

func main() {
	fmt.Println(GetVersion())
}
