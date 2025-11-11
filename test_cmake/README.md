# CMake Test Example

This example demonstrates using gwrap as a drop-in replacement for g++ with CMake.

## Prerequisites

1. Install a package first in the parent directory:
```powershell
cd ..
.\gwrap.exe config init
.\gwrap.exe install nlohmann-json
```

2. Copy `cpp_modules/` and `cpp_package.json` to this directory:
```powershell
Copy-Item ..\cpp_modules .\cpp_modules -Recurse
Copy-Item ..\cpp_package.json .\cpp_package.json
```

## Build

```powershell
# Configure with gwrap as compiler
cmake -G "MinGW Makefiles" -DCMAKE_CXX_COMPILER="..\gwrap.exe" .

# Build
mingw32-make

# Run
.\cmake_test.exe
```

## Expected Output

```json
{
  "auto_includes": true,
  "message": "CMake + Gwrap working!"
}
```

## How It Works

- CMake uses gwrap instead of g++
- gwrap automatically adds `-I` flags for packages in `cpp_modules/`
- No changes to `CMakeLists.txt` required
- Works transparently with any build system
