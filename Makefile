
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

ifeq ($(PLATFORM),PLATFORM_WEB)
	BIN_MODE = build-lib
	ZFLAGS += -target wasm32-freestanding --sysroot $(EMSDK_PATH)/upstream/emscripten
#	LFLAGS += -s USE_GLFW=3 -s TOTAL_MEMORY=128MB -s FORCE_FILESYSTEM=1 -s WASM=1 -s USE_WEBGL2=1
endif

BIN ?= zrayjam

$(BIN): Makefile $(RAYLIB_BIN_PATH)
ifeq ($(PLATFORM),PLATFORM_WEB)
	zig $(BIN_MODE) --name $(BIN) main.zig $(ZFLAGS) $(IFLAGS) $(LFLAGS)
	emcc -c entry.c
	#emcc -o ./ok.html entry.o libzrayjam.a ext/raylib/src/libraylib_PLATFORM_WEB.a -s USE_GLFW=3 -s TOTAL_MEMORY=128MB -s FORCE_FILESYSTEM=1 -DPLATFORM_WEB --shell-file minshell
	emcc -o $(BIN).html entry.o lib$(BIN).a $(RAYLIB_BIN_PATH) -s USE_GLFW=3 -s TOTAL_MEMORY=128MB -s FORCE_FILESYSTEM=1 -DPLATFORM_WEB --shell-file minshell
else
	zig cc -c entry.c
	zig cc -c main.zig
	zig $(BIN_MODE) --name $(BIN) main.o entry.o $(ZFLAGS) $(IFLAGS) $(LFLAGS)
endif

$(RAYLIB_BIN_PATH):
	make -C $(RAYLIB_PATH) clean
	make -C $(RAYLIB_PATH)
	mv $(RAYLIB_PATH)/$(RAYLIB_BIN) $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)
