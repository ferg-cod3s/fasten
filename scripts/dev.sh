#!/bin/bash
# Development helper script

set -e

case "$1" in
    "setup")
        echo "Setting up Fasten development environment..."
        # Install Zig Language Server if not present
        if ! command -v zls &> /dev/null; then
            echo "Installing Zig Language Server..."
            # Add installation commands based on your system
        fi
        echo "✅ Development environment setup complete"
        ;;
    "build")
        echo "Building Fasten..."
        zig build
        echo "✅ Build complete"
        ;;
    "test")
        echo "Running tests..."
        zig build test
        echo "✅ Tests complete"
        ;;
    "run")
        shift
        echo "Running Fasten with args: $@"
        zig build run -- "$@"
        ;;
    *)
        echo "Usage: $0 {setup|build|test|run}"
        echo "  setup - Set up development environment"
        echo "  build - Build the project" 
        echo "  test  - Run all tests"
        echo "  run   - Run fasten with arguments"
        exit 1
        ;;
esac