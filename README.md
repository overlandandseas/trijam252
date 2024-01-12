### running late, sry

This is my entry for Trijam #252. I wanted to try a fast jam, and give zig a spin.

### disclaimer

this doesn't work great. the wasm build didn't seem to support zig's heap page allocator. I changed the `sprintf`'s to use an existing buffer on the stack, but that now seems to make the desktop build segfault :/


### Build Req

Native: `make`

Wasm: 
 - install the `emsdk`
 - if `emsdk` is at `~/.emsdk`, just use `make PLATFORM=PLATFORM_WEB`
 - you can override the `emsdk` path with `make PLATFORM=PLATFORM_WEB EMSDK_PATH=/some/path`

### Notes
The following are hacks, which hopefully will no longer be required after zig 0.11
 - `entry.c` and it's contents
 - `wasm32-freestanding` (as opposed to `wasm32-emscripten`)
 - the usage of the emscripten linker
