use foo_command::{export, exports::wasi::cli::run::Guest};
use foo_command::test::foo::custom::words;

struct RunnerImpl;

impl Guest for RunnerImpl {
    fn run() -> Result<(), ()> {
        let the_words = words("Are these words?");

        assert!(the_words.len() == 3);

        Ok(())
    }
}

export!(RunnerImpl);