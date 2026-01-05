#!/bin/bash
# Rebuild script for llama.cpp in Codespaces

cd Mind/llama.cpp
echo "Building llama.cpp using CMake..."

# Create build directory
mkdir -p build
cd build

# Configure with CMake (release build)
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build using all available cores
cmake --build . --config Release -j$(nproc)

echo "Build complete."

# locate the server binary and move it to Mind/root
echo "Locating built binary..."
find . -name "llama-server" -type f

if [ -f "bin/llama-server" ]; then
    cp bin/llama-server ../../llama-server
    echo "Copied bin/llama-server to Mind/llama-server"
elif [ -f "llama-server" ]; then
    cp llama-server ../../llama-server
    echo "Copied llama-server to Mind/llama-server"
else
     echo "Could not auto-locate llama-server binary. Please check build output."
fi

# Ensure executable permissions
chmod +x ../../llama-server
