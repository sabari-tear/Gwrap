# Gwrap 📦

> An npm-like package manager for C++ powered by vcpkg

Automatically manages C++ dependencies and includes them when compiling. No more manual `-I` flags!

## Features

- **Install packages** with `gwrap install <package-name>` using vcpkg
- **Auto-include** all installed packages when compiling
- **Track dependencies** in `cpp_package.json` (like package.json)
- **Store locally** in `cpp_modules/` (like node_modules)

## Quick Start

### Prerequisites

1. **vcpkg** - Install from https://github.com/microsoft/vcpkg
2. **g++** - MinGW-w64 or any compatible C++ compiler

### Installation

```powershell
# Build gwrap
g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe

# Configure tool paths (auto-detects or prompts for paths)
.\gwrap.exe config init
```

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

## CMake Integration

Gwrap works as a drop-in replacement for g++ in CMake projects:

```powershell
# Copy cpp_modules/ to your CMake project directory
# Then configure:
cmake -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER="path/to/gwrap.exe" .
mingw32-make
```

See `test_cmake/` for a complete example.

## Common Commands

```powershell
# Setup
.\gwrap.exe config init                    # Auto-detect tools
.\gwrap.exe config show                    # Show current config
.\gwrap.exe config set vcpkg <path>        # Set vcpkg path
.\gwrap.exe config set gpp <path>          # Set g++ path

# Package management
.\gwrap.exe install <package>              # Install package
.\gwrap.exe update                         # Update all packages

# Compilation (just like g++)
.\gwrap.exe -std=c++17 main.cpp -o main.exe
.\gwrap.exe -std=c++20 -O3 main.cpp -o main.exe
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
