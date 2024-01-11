// this sucks
// but seems to be required with zig 0.11

#include <stdint.h>
#include <stdlib.h>
// Zig compiles C code with -fstack-protector-strong which requires the following two symbols
// which don't seem to be provided by the emscripten toolchain(?)
uintptr_t __stack_chk_guard = 0xABBABABA;
_Noreturn void __stack_chk_fail(void) { abort(); };