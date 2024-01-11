
IFLAGS ?=
LFLAGS ?=
ZFLAGS ?=

## PLATFORM
PLATFORM        ?= PLATFORM_DESKTOP

## EMSCRIPTEN
EMSDK_PATH      ?= ~/.emsdk

## RAYLIB STUFF
RAYLIB_PATH     ?= ext/raylib/src
RAYLIB_BIN      ?= libraylib.a
RAYLIB_PLAT_BIN ?= libraylib_$(PLATFORM).a
RAYLIB_BIN_PATH ?= $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)

IFLAGS += -I$(RAYLIB_PATH)
LFLAGS += -L$(RAYLIB_PATH) -lc -lraylib_$(PLATFORM)

ifeq ($(PLATFORM),PLATFORM_WEB)
	ZFLAGS += -Dtarget=wasm32-emscripten --sysroot $(EMSDK_PATH)/upstream/emscripten
	LFLAGS += -s USE_GLFW=3 -s TOTAL_MEMORY=128MB -s FORCE_FILESYSTEM=1 -s WASM=1 -s USE_WEBGL2=1
endif

BIN ?= zrayjam

$(BIN): Makefile $(RAYLIB_BIN_PATH)
	zig build-exe --name $(BIN) main.zig $(ZFLAGS) $(IFLAGS) $(LFLAGS)

$(RAYLIB_BIN_PATH):
	make -C $(RAYLIB_PATH) clean
	make -C $(RAYLIB_PATH)
	mv $(RAYLIB_PATH)/$(RAYLIB_BIN) $(RAYLIB_PATH)/$(RAYLIB_PLAT_BIN)