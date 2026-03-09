package dependency

import "fmt"

func DoSomething(wordSeparator func(string) []string) {
	theWords := wordSeparator("These are fersher words.")

	if len(theWords) == 4 {
		fmt.Println("It worked")
	} else {
		panic("Something is messed up!")
	}
}
