use command::{export, exports::wasi::cli::run::{Guest}};
use command::wasi::cli::stdout::get_stdout;

struct CommandImpl;

impl Guest for CommandImpl {
    fn run() -> Result<(), ()> {
        get_stdout().write(b"I'm a command.").map_err(|_| ())?;
        Ok(())
    }
}

export!(CommandImpl);