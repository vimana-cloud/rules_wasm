use command::exports::wasi::cli::run::Guest;

struct RunnerImpl;

impl Guest for RunnerImpl {
    fn run() -> Result<(), ()> {
        Ok(())
    }
}
