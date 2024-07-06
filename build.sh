#!/bin/bash
set -e

WORK_DIR=$(readlink -f .)
SCRIPT_DIR=$(readlink -f ./scripts)
cd $WORK_DIR

CPYTHON_VERSION=3.11.9
ATHERIS_VERSION=2.3.0
ATHERIS_PATH=$(readlink -f ./atheris)
CPYTHON_PATH=$(readlink -f ./cpython)
BUILD_PATH=$(readlink -f build)
SRC_PATH=$(readlink -f ./src)
PATCHED_PATH=$(readlink -f ./patched_libs)
USING_CORE=7

SKIP_ATHERIS=0

# COLORs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# parse args skip-afl and skip-cpython
while [ "$1" != "" ]; do
    case $1 in
        -a | --skip-atheris )   SKIP_ATHERIS=1
                                ;;
        -j | --jobs )           shift
                                USING_CORE=$1
                                ;;
        --clean )               rm -rf $ATHERIS_PATH $BUILD_PATH $CPYTHON_PATH
                                exit
                                ;;
        * )                     echo "Invalid argument $1"
                                exit
                                ;;
    esac
    shift
done

if [ -d $ATHERIS_PATH ]; then
    echo -e "[WARN] using cached atheris"
else
    echo -e "[INFO] cloning atheris into $ATHERIS_PATH"
    git clone --quiet --depth=1 --branch=$ATHERIS_VERSION https://github.com/google/atheris.git $ATHERIS_PATH
fi

if [ -d $CPYTHON_PATH ]; then
    echo -e "[WARN] using cached cpython"
else
    echo -e "[INFO] cloning cpython into $CPYTHON_PATH"
    git clone --quiet --depth=1 --branch=v$CPYTHON_VERSION https://github.com/python/cpython.git $CPYTHON_PATH
    cd $WORK_DIR
fi

if [ $SKIP_ATHERIS -eq 1 ]; then
    echo -e "[INFO] skip building cpython and/or atheris"
else
    cd $ATHERIS_PATH

    # PATCHING
    echo -e "${GREEN}[INFO] patching Atheris$NC"
    cd $ATHERIS_PATH
    git reset --hard HEAD
    git apply $WORK_DIR/atheris-nix-bash.patch

    echo -e "${GREEN}[INFO] patching CPython$NC"
    cd $CPYTHON_PATH
    git reset --hard HEAD
    python $SCRIPT_DIR/patch_python.py

    cd $WORK_DIR

    echo -e "${GREEN}[INFO] building Atheris$NC"
    nix-shell --pure --command "echo -e '${GREEN}[INFO] finished building Atheris$NC'" $SCRIPT_DIR/cpython.nix --argstr py_ver_str $CPYTHON_VERSION
    
    echo -e "${GREEN}[INFO] patching cpython lib$NC"
    nix-shell --pure --command "python $SCRIPT_DIR/patch_python.py \$PYTHON_PATH $PATCHED_PATH" $SCRIPT_DIR/cpython.nix --argstr py_ver_str $CPYTHON_VERSION
fi

echo -e "${GREEN}[INFO] building pyFuzzer$NC"
mkdir -p $BUILD_PATH
cd $BUILD_PATH
nix-shell --pure --command "cmake $SRC_PATH" $SCRIPT_DIR/cpython.nix --argstr py_ver_str $CPYTHON_VERSION
nix-shell --pure --command "make -j$USING_CORE" $SCRIPT_DIR/cpython.nix --argstr py_ver_str $CPYTHON_VERSION
