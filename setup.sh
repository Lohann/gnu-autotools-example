#!/usr/bin/env bash

set -euo pipefail

# Prevent locale nonsense from breaking basic text processing.
LC_ALL=C
export LC_ALL

# display a message then exit
abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# check required binaries
require_bin(){
    test "$#" -eq '1' || abort "[BUG]: usage \"require_bin <bin_name>\""
    test -z "${1}"    && abort "[BUG]: bin_name cannot be empty"
    command -v "${1}" > /dev/null 2>&1 || abort "'${1}' not found"
}

# check dependencies
require_bin dirname
require_bin make
require_bin autoreconf

# make sure we are in the right directory
cd -- "$(dirname "${0}")" || abort "command 'cd -- \$(basename \"${0}\")' failed"
pushd 'example' &> /dev/null

execute_with(){
    printf -- '---------------------- %s ----------------------\n' "${1}"
    shift 1
    "$@"
    # printf -- '------------------------------------------------\n'
}

# display
show_usage(){
    echo "usage: ${0} [-h|--help] [--cleanup]"
    echo "Available options: "
    echo "  --all       |  equivalent to provide '--cleanup --build --execute'"
    echo "  --build     |  compile code"
    echo "  --execute   |  execute code"
    echo "  --cleanup   |  remove all auto-generated and build files"
    echo "  --help | -h |  show this message"
}

# check required binaries
cleanup_autotools(){
    test -d ./build && rm -rfv ./build
    test -d ./autom4te.cache && rm -rfv ./autom4te.cache
    test -d ./tools && rm -rfv ./tools
    test -f ./aclocal.m4 && rm -fv ./aclocal.m4
    test -f ./config.h.in && rm -fv ./config.h.in
    test -f ./configure && rm -fv ./configure
    test -f ./Makefile.in && rm -fv ./Makefile.in
    test -f ./src/Makefile.in && rm -fv ./src/Makefile.in
}

# configure and compile
compile(){
    test -f ./configure || abort "configure file not found"
    if test -d ./build; then
        rm -rf ./build/*
    else
        mkdir ./build
    fi
    pushd 'build' &> /dev/null
    ../configure
    make
    popd &> /dev/null
}

# if no args, show usage.
if test "$#" -eq '0'; then
    show_usage
    exit 0
fi

# extract options from provided args.
_do_setup='0'
_do_cleanup='0'
_do_compile='0'
_do_execute='0'
for opt in "$@"; do
    case "${opt}" in
        -h|--help)      show_usage && exit 0   ;;
        '--cleanup')    _do_cleanup='1'        ;;
        '--no-cleanup') _do_cleanup='0'        ;;
        '--build')      _do_compile='1'        ;;
        '--no-build')   _do_compile='0'        ;;
        '--execute')    _do_execute='1'        ;;
        '--no-execute') _do_execute='0'        ;;
        '--all')
            _do_cleanup='1'
            _do_compile='1'
            _do_execute='1'
            ;;
        *)
            echo "[ERROR] unknown option: '${opt}'";
            show_usage
            exit 1
            ;;
    esac
done

# if executable doesn't exists, compile it.
if ! test -f ./build/src/hello; then
    test "${_do_execute}" == '1' && _do_compile='1'
fi

# if configure file doesn't exists, setup autotools.
if ! test -f ./configure; then
    if test "${_do_compile}" == '1'; then
        _do_setup='1'
    fi
fi

# do cleanup
test "${_do_cleanup}" == '1' && { execute_with 'cleanup' 'cleanup_autotools'; }

# install autotools
test "${_do_setup}" == '1' && { execute_with 'autoreconf' autoreconf --install -Wall --force --verbose; }

# Compile
test "${_do_compile}" == '1' && { execute_with 'compile' compile; }

# Execute
test "${_do_execute}" == '1' && { execute_with 'execute' ./build/src/hello; } 

# ./src/configure
# - probes the systems for required functions, libraries, and tools
# - then it generates a config.h file with all #defines
# - as well as Makefiles to build the package

# DEFAULT ENVIRONMENT VARIABLES
# - CC C compiler command
# - CFLAGS C compiler flags
# - CXX C++ compiler command
# - CXXFLAGS C++ compiler flags
# - LDFLAGS linker flags
# - CPPFLAGS C/C++ preprocessor flags
