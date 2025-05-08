// TinyGo currently can only compile Wasm components that implement `wasi:cli/run`,
// which means it needs to have package "main" and implement a `main` function.
// To implement a reactor component, just use an empty `main` function.
// https://github.com/tinygo-org/tinygo/issues/4843
package main

import (
	"fmt"

	"example.com/wit/test/foo/custom"
)

func main() {
	theWords := custom.Words("These are fersher words.")

	if theWords.Len() == 4 {
		fmt.Println("It worked")
	} else {
		panic("Something is messed up!")
	}
}
