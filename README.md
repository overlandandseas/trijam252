
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
