# include, linker, zig, emcc
IFLAGS ?=
LFLAGS ?=
ZFLAGS ?=
EFLAGS ?=

## PLATFORM
PLATFORM        ?= PLATFORM_DESKTOP
ZFLAGS          += -D$(PLATFORM)

## EMSCRIPTEN
EMSDK_PATH      ?= ~/.emsdk

## RAYLIB STUFF
RAYLIB_PATH     ?= ext/raylib/src
RAYLIB_BIN      ?= libraylib.a
RAYLIB_PLAT_BIN ?= libraylib_$(PLATFORM).a
RAYLIB_BIN_PATH ?= $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)

IFLAGS += -I$(RAYLIB_PATH)
LFLAGS += -L$(RAYLIB_PATH) -lc -lraylib_$(PLATFORM)

EFLAGS += -O3 -s ALLOW_MEMORY_GROWTH=1 -s ASYNCIFY -s USE_GLFW=3 -s TOTAL_MEMORY=256MB -s FORCE_FILESYSTEM=1 -DPLATFORM_WEB --shell-file minshell --preload-file res

# game name
BIN ?= zrayjam
# either zrayjam or zrayjam.wasm
FINAL_BIN ?= $(BIN)

# platform-specific flags, mostly linkage
ifeq ($(PLATFORM),PLATFORM_WEB)
	FINAL_BIN = zrayjam.wasm
	ZFLAGS += -target wasm32-wasi --sysroot $(EMSDK_PATH)/upstream/emscripten
else ifeq ($(PLATFORM),PLATFORM_DESKTOP)
	ifeq ($(OS),Windows_NT)
		PLATFORM_OS = WINDOWS
		LFLAGS += -lopengl32 -lgdi32 -lwinmm -lcomdlg32 -lole32
	else
		UNAMEOS = $(shell uname)
		ifeq ($(UNAMEOS),Linux)
			PLATFORM_OS = LINUX
			LFLAGS += -lGL -lrt -ldl -lm -lX11
		endif
		ifeq ($(UNAMEOS),Darwin)
			PLATFORM_OS = OSX
			LFLAGS += -framework Foundation -framework Cocoa -framework OpenGL -framework CoreAudio -framework CoreVideo -framework IOKit
		endif
	endif
endif

# final artifact
$(FINAL_BIN): Makefile $(RAYLIB_BIN_PATH) main.zig
ifeq ($(PLATFORM),PLATFORM_WEB)
	emcc -c entry.c
	zig build-lib --name $(BIN) $(IFLAGS) $(ZFLAGS) $(LFLAGS) main.zig 
	emcc -o $(BIN).html entry.o lib$(BIN).a $(RAYLIB_BIN_PATH) $(EFLAGS)
else
	zig cc -c entry.c
	zig cc -c main.zig $(IFLAGS)
	zig build-exe --name $(BIN) main.o entry.o $(ZFLAGS) $(IFLAGS) $(LFLAGS)
endif

# libraylib.a -> libraylib_$(PLATFORM).a
$(RAYLIB_BIN_PATH):
	echo $(RAYLIB_BIN_PATH)
	make -C $(RAYLIB_PATH) clean
	make -C $(RAYLIB_PATH)
	mv $(RAYLIB_PATH)/$(RAYLIB_BIN) $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)

clean:
	rm -f *.o
	rm -f *.a
	rm -f *.html
	rm -f *.js
	rm -f *.wasm
	rm -f *.exe
	rm -f $(BIN)