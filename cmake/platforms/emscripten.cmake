# Emscripten specific settings

if(NOT EMSCRIPTEN)
    return()
endif()

set(CMAKE_EXECUTABLE_SUFFIX ".js")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".wasm")

# Disable options that don't make sense for emscripten
set(BUILD_SERVER OFF CACHE INTERNAL "")
set(BUILD_RENDERER_GL1 OFF CACHE INTERNAL "")
set(USE_RENDERER_DLOPEN OFF CACHE INTERNAL "")
set(USE_OPENAL_DLOPEN OFF CACHE INTERNAL "")
set(BUILD_GAME_LIBRARIES OFF CACHE INTERNAL "")
set(USE_HTTP OFF CACHE INTERNAL "")

# Disable LTO since the libraries Emscripten provides aren't LTO enabled
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION FALSE)

list(APPEND CLIENT_LINK_OPTIONS
    -sTOTAL_MEMORY=256MB
    -sSTACK_SIZE=5MB
    -sMIN_WEBGL_VERSION=1
    -sMAX_WEBGL_VERSION=2
    -sEXPORTED_RUNTIME_METHODS=FS,addRunDependency,removeRunDependency
    -sEXIT_RUNTIME=1
    -sMODULARIZE=1
    -sEXPORT_NAME=${CLIENT_NAME}
)

option(EMSCRIPTEN_ASMJS "Build asm.js JavaScript output instead of WebAssembly" OFF)

if(EMSCRIPTEN_ASMJS)
    # Force asm.js / pure-JS output. No .wasm file is produced. Linking with
    # ports (SDL2, libjpeg, zlib, ogg, vorbis, opus, freetype) will recompile
    # them to asm.js as needed, which makes the link step considerably slower.
    list(APPEND CLIENT_COMPILE_OPTIONS -sWASM=0)
    list(APPEND CLIENT_LINK_OPTIONS -sWASM=0)
    # Asm.js is slow enough that synchronous map loading blocks the browser
    # event loop for several seconds, so the loading wallpaper / progress
    # never paints. Asyncify lets SDL_GL_SwapWindow yield to the browser
    # between intermediate SCR_UpdateScreen calls so each frame is composited.
    list(APPEND CLIENT_LINK_OPTIONS -sASYNCIFY=1 -sASYNCIFY_STACK_SIZE=24576)
endif()

option(EMSCRIPTEN_PRELOAD_FILE "Preload game files into .data file" OFF)

if(EMSCRIPTEN_PRELOAD_FILE)
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/${BASEGAME}")
        message(FATAL_ERROR "No files in '${BASEGAME}' directory for emscripten to preload.")
    endif()
    list(APPEND CLIENT_LINK_OPTIONS --preload-file "${BASEGAME}")
endif()

list(APPEND POST_CONFIGURE_FUNCTIONS deploy_shell_files)

function(deploy_shell_files)
    configure_file(${SOURCE_DIR}/web/client.html.in
        ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${CLIENT_NAME}.html @ONLY)

    if(NOT EMSCRIPTEN_PRELOAD_FILE)
        configure_file(${SOURCE_DIR}/web/client-config.json
            ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${CLIENT_NAME}-config.json COPYONLY)
    endif()
endfunction()
