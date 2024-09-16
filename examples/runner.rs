use command::{export, exports::wasi::cli::run::{Guest}};
use command::wasi::cli::stdout::get_stdout;

struct RunnerImpl;

impl Guest for RunnerImpl {
    fn run() -> Result<(), ()> {
        let stdout = get_stdout();
        stdout.write(b"It's running!").map_err(|_| ())?;

        // TODO: Figure out a way to verify that the test is *actually running*
        //   rather than manually inspecting stdout.

        Ok(())
    }
}

export!(RunnerImpl);