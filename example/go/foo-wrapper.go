// TinyGo currently can only compile Wasm components that implement `wasi:cli/run`,
// which means it needs to have package "main" and implement a `main` function.
// To implement a reactor component, just use an empty `main` function.
// https://github.com/tinygo-org/tinygo/issues/4843
package main

import (
	"example.com/wit/test/foo/custom"

	"this-is.a/dependency"
)

func main() {
	dependency.DoSomething(func(s string) []string {
		return custom.Words(s).Slice()
	})
}
