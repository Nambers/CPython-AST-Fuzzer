#!/bin/bash
set -e

###
# setup environment and type hints for vscode
###

WORK_DIR=$(readlink -f .)
SCRIPT_DIR=$(readlink -f ./scripts)
CPYTHON_BIN_PATH=$(readlink -f ./cpython_bin/include/python3.*)
CLANG_BIN=$(nix-shell --pure --command "echo \$CLANG_BIN" "$SCRIPT_DIR/cpython.nix")

# VSCode IntelliSense config
cat > "$WORK_DIR/.vscode/c_cpp_properties.json" <<EOF
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "$CPYTHON_BIN_PATH/",
                "$CPYTHON_BIN_PATH/internal"
            ],
            "defines": [],
            "compilerPath": "$CLANG_BIN",
            "cStandard": "c17",
            "cppStandard": "c++17",
            "intelliSenseMode": "linux-clang-x64"
        }
    ],
    "version": 4
}
EOF

# VSCode settings
cat > "$WORK_DIR/.vscode/settings.json" <<EOF
{
    "cmake.sourceDirectory": "\${workspaceFolder}/src",
    "cmake.buildDirectory": "\${workspaceFolder}/build",
    "C_Cpp.default.compilerPath": "$CLANG_BIN",
    "cmake.configureEnvironment": {
        "PYTHON_PATH": "$CPYTHON_BIN_PATH"
    }
}
EOF

# Clangd config
cat > "$WORK_DIR/.clangd" <<EOF
CompileFlags:
  Add: [
    "-I$CPYTHON_BIN_PATH",
    "-I$CPYTHON_BIN_PATH/internal"
  ]
EOF
