#include "c/foo_command.h"

bool exports_wasi_cli_run_run(void) {
    foo_command_string_t sentence;
    foo_command_list_string_t words;

    foo_command_string_set(&sentence, "What is a word?");
    test_foo_custom_words(&sentence, &words);

    return words.len == 4;
}
