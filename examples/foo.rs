struct FooImpl;

impl the_world::Guest for FooImpl {
    fn words(text: String) -> Vec<String> {
        // Split the string into words.
        let words: Vec<String> = text.split(' ').map(String::from).collect();
        // Log the number of words.
        the_world::log_activity(&format!("Counted {} words.", words.len()));
        // Return the list of words.
        words
    }
}

the_world::export!(FooImpl);
