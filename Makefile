
IFLAGS ?=
LFLAGS ?=
ZFLAGS ?=

## PLATFORM
PLATFORM        ?= PLATFORM_DESKTOP
ZFLAGS += -D$(PLATFORM)

## EMSCRIPTEN
EMSDK_PATH      ?= ~/.emsdk

## RAYLIB STUFF
RAYLIB_PATH     ?= ext/raylib/src
RAYLIB_BIN      ?= libraylib.a
RAYLIB_PLAT_BIN ?= libraylib_$(PLATFORM).a
RAYLIB_BIN_PATH ?= $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)

IFLAGS += -I$(RAYLIB_PATH)
LFLAGS += -L$(RAYLIB_PATH) -lc -lraylib_$(PLATFORM)

EFLAGS ?= 

BIN_MODE ?= build-exe
BIN ?= zrayjam
FINAL_BIN ?= $(BIN)

ifeq ($(PLATFORM),PLATFORM_WEB)
	BIN_MODE = build-lib
	FINAL_BIN = zrayjam.wasm
	ZFLAGS += -target wasm32-freestanding --sysroot $(EMSDK_PATH)/upstream/emscripten
else ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS = WINDOWS
    else
        UNAMEOS = $(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS = LINUX
			LFLAGS += -lGL -lrt -ldl -lm -lX11
        endif
        ifeq ($(UNAMEOS),FreeBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),OpenBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),NetBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),DragonFly)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS = OSX
			LFLAGS += -framework Foundation -framework Cocoa -framework OpenGL -framework CoreAudio -framework CoreVideo -framework IOKit
        endif
    endif
endif

$(FINAL_BIN): Makefile $(RAYLIB_BIN_PATH)
ifeq ($(PLATFORM),PLATFORM_WEB)
	zig $(BIN_MODE) --name $(BIN) main.zig $(ZFLAGS) $(IFLAGS) $(LFLAGS)
	emcc -c entry.c
	emcc -o $(BIN).html entry.o lib$(BIN).a $(RAYLIB_BIN_PATH) -s ASYNCIFY -s USE_GLFW=3 -s TOTAL_MEMORY=128MB -s FORCE_FILESYSTEM=1 -DPLATFORM_WEB --shell-file minshell
else
	zig cc -c entry.c
	zig cc -c main.zig $(IFLAGS)
	zig $(BIN_MODE) --name $(BIN) main.o entry.o $(ZFLAGS) $(IFLAGS) $(LFLAGS)
endif

$(RAYLIB_BIN_PATH):
	make -C $(RAYLIB_PATH) clean
	make -C $(RAYLIB_PATH)
	mv $(RAYLIB_PATH)/$(RAYLIB_BIN) $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)
