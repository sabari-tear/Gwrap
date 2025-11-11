# Gwrap 📦

> A transparent g++ wrapper that adds npm-like package management to C++

**Replace your g++ with gwrap** and get automatic dependency management without changing your workflow. Works seamlessly with CMake, Makefiles, and any build system.

## The Magic ✨

```powershell
# 1. Rename gwrap to g++
Copy-Item gwrap.exe g++.exe

# 2. Put it in your PATH before real g++
# 3. That's it! Now:

# Your CMakeLists.txt doesn't change:
cmake . && make

# Your Makefiles don't change:
make

# Your build scripts don't change:
g++ main.cpp -o app.exe

# But NOW you can:
g++ install nlohmann-json    # Install packages!
g++ update                   # Update them!
# And they're automatically included in ALL compilations
```

**No project modifications. No build system changes. Just better C++.**

## Why Gwrap?

**Use gwrap as a drop-in replacement for g++** - no changes to your existing projects needed!

- 🔄 **Transparent**: Acts exactly like g++, just with automatic includes
- 📦 **Package management**: Install C++ libraries with one command
- 🏗️ **Build system compatible**: Works with CMake, Make, and direct compilation
- 🎯 **Zero configuration**: Replace g++ in your PATH, everything works instantly

## Features

- Install packages with `gwrap install <package-name>` using vcpkg
- Auto-include all installed packages when compiling
- Track dependencies in `cpp_package.json` (like package.json)
- Store locally in `cpp_modules/` (like node_modules)
- **100% compatible with g++ commands** - use it anywhere g++ is used

## Quick Start

### Prerequisites

1. **vcpkg** - Install from https://github.com/microsoft/vcpkg
2. **g++** - MinGW-w64 or any compatible C++ compiler

### Installation

#### Option 1: Use gwrap directly (recommended for trying it out)

```powershell
# Build gwrap
g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe

# Configure tool paths (auto-detects)
.\gwrap.exe config init

# Use it like g++
.\gwrap.exe -std=c++17 main.cpp -o main.exe
```

#### Option 2: Replace g++ system-wide (seamless integration)

```powershell
# Build gwrap
g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe

# Rename gwrap to g++
Copy-Item gwrap.exe g++.exe

# Add to PATH (Windows example):
# Create a directory like C:\gwrap
# Copy g++.exe there
# Add C:\gwrap to your PATH BEFORE the real g++ path
# OR replace real g++ directly (backup first!)

# Configure once
g++.exe config init
```

**How PATH works:**
- Windows searches PATH directories left-to-right
- Put gwrap's directory BEFORE your MinGW/GCC directory
- Now `g++` resolves to gwrap, but gwrap can still find real g++

**Now every tool transparently uses gwrap:**
- ✅ CMake: `cmake .` (no -DCMAKE_CXX_COMPILER needed)
- ✅ Make: `make` (automatically uses g++ from PATH)
- ✅ IDEs: Visual Studio Code, CLion (use g++ from PATH)
- ✅ Build scripts: Any script calling `g++` gets gwrap
- ✅ Manual: `g++ main.cpp -o app.exe` works everywhere

### Usage

```powershell
# First time: Initialize configuration
.\gwrap.exe config init

# Install a C++ package
.\gwrap.exe install nlohmann-json

# Install another package
.\gwrap.exe install fmt

# Update all packages to latest versions
.\gwrap.exe update

# Compile your code (auto-includes all packages from cpp_modules)
.\gwrap.exe -std=c++17 main.cpp -o main.exe

# Run your program
.\main.exe
```

## How It Works

1. **`gwrap install <package>`** 
   - Uses vcpkg to download and install the package
   - Copies headers to `cpp_modules/<package>/include/`
   - Copies libraries to `cpp_modules/<package>/lib/`
   - Updates `cpp_package.json` with package info

2. **`gwrap update`**
   - Checks all packages in `cpp_package.json` for updates
   - Shows available updates with version comparison
   - Updates all packages to latest versions with confirmation

3. **`gwrap config`**
   - `gwrap config init` - Auto-detect and save tool paths
   - `gwrap config show` - Display current configuration
   - `gwrap config set vcpkg <path>` - Set vcpkg path manually
   - `gwrap config set gpp <path>` - Set g++ path manually

4. **`gwrap <g++ args>`**
   - Reads `gwrap_config.json` for g++ path
   - Reads `cpp_package.json` for include paths
   - Automatically adds `-I` flags for all packages
   - Forwards everything to configured g++

## Project Structure

```
your-project/
├── gwrap.exe              # The package manager + compiler wrapper
├── cpp_package.json       # Dependency tracking
├── cpp_modules/           # Installed packages
│   ├── nlohmann_json/
│   │   ├── include/
│   │   └── lib/
│   └── fmt/
│       ├── include/
│       └── lib/
└── main.cpp              # Your code
```

## Example

```cpp
// main.cpp
#include <iostream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

int main() {
    json j;
    j["project"] = "Gwrap";
    j["version"] = "1.0.0";
    
    std::cout << j.dump(4) << std::endl;
    return 0;
}
```

```powershell
# Install nlohmann-json
.\gwrap.exe install nlohmann-json

# Compile (no need to specify -I flags!)
.\gwrap.exe -std=c++17 main.cpp -o main.exe

# Run
.\main.exe
```

## Available Packages

Any package available in vcpkg! Common ones:

- `nlohmann-json` - JSON library
- `fmt` - Formatting library
- `spdlog` - Logging library
- `catch2` - Testing framework
- `boost` - Boost libraries

Search vcpkg for more: `vcpkg search <query>`

## Configuration

`cpp_package.json` example:

```json
{
  "name": "my-cpp-project",
  "version": "1.0.0",
  "dependencies": {
    "nlohmann-json": {
      "version": "3.12.0",
      "include": "cpp_modules/nlohmann_json/include",
      "lib": "cpp_modules/nlohmann_json/lib"
    }
  },
  "compiler": {
    "standard": "c++17",
    "optimization": "-O2"
  }
}
```

## Notes

- Packages are installed to the **current directory's** `cpp_modules/`
- Each project has its own local packages (like node_modules)
- vcpkg installs packages globally, but gwrap copies them locally
- Currently supports x64-windows target

## Transparent Integration Examples

### CMake (No Changes Needed!)

If gwrap is renamed to `g++.exe` and in your PATH:

```powershell
# Your existing CMake projects just work:
cmake -G "MinGW Makefiles" .
make
```

Or specify gwrap explicitly:

```powershell
cmake -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER="path/to/gwrap.exe" .
make
```

### Makefiles (No Changes Needed!)

```makefile
# Your existing Makefile works as-is:
CXX = g++  # This calls gwrap if renamed to g++
CXXFLAGS = -std=c++17 -O2

main: main.cpp
	$(CXX) $(CXXFLAGS) main.cpp -o main
```

### Direct Compilation (Drop-in Replacement)

```powershell
# Before (with manual includes):
g++ -std=c++17 -Icpp_modules/nlohmann_json/include main.cpp -o main.exe

# After (automatic includes):
g++.exe -std=c++17 main.cpp -o main.exe  # gwrap renamed to g++.exe
```

See `test_cmake/` for a complete example.

## Common Commands

```powershell
# One-time setup
g++.exe config init                    # Auto-detect tools (if renamed to g++.exe)

# Package management
g++.exe install <package>              # Install package
g++.exe update                         # Update all packages

# Compilation (100% compatible with g++)
g++.exe -std=c++17 main.cpp -o main.exe
g++.exe -std=c++20 -O3 main.cpp -o main.exe
g++.exe --version                      # Works exactly like g++
g++.exe -E -dM                         # All g++ flags work

# Configuration (optional)
g++.exe config show                    # Show current config
g++.exe config set vcpkg <path>        # Set vcpkg path
g++.exe config set gpp <path>          # Set real g++ path
```

## Contributing

Contributions welcome! 

1. Fork the repository
2. Build: `g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe`
3. Test your changes
4. Submit a pull request

## Project Structure

```
Gwrap/
├── gwrap.cpp              # Main wrapper program
├── gwrap.exe              # Compiled binary
├── gwrap_config.ps1       # Configuration management
├── vcpkg_install.ps1      # Package installation
├── vcpkg_update.ps1       # Package updates
├── test_cmake/            # CMake integration example
└── README.md              # This file
```

## License

MIT
