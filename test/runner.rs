use command::{export, exports::wasi::cli::run::{Guest}};
use command::wasi::cli::stdout::get_stdout;

struct RunnerImpl;

impl Guest for RunnerImpl {
    fn run() -> Result<(), ()> {
        get_stdout().write(b"Is this thing on?").map_err(|_| ())?;
        Ok(())
    }
}

export!(RunnerImpl);