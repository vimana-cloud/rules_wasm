use the_world::exports::test::foo::custom::Guest;

struct FooImpl;

impl Guest for FooImpl {
    fn words(text: String) -> Vec<String> {
        // Split the string into words.
        text.split(' ').map(String::from).collect()
    }
}

the_world::export!(FooImpl);
