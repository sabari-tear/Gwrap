#include <iostream>
#include <string>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <vector>
#include <sstream>
using namespace std;
namespace fs = std::filesystem;

// Load g++ path from config
string getGppPath() {
    if (!fs::exists("gwrap_config.json")) {
        // Try default g++ if no config
        return "g++";
    }
    
    ifstream configFile("gwrap_config.json");
    if (!configFile) {
        return "g++";
    }
    
    string content;
    string line;
    while (getline(configFile, line)) {
        content += line;
    }
    
    // Simple JSON parsing for gpp_path
    size_t pos = content.find("\"gpp_path\"");
    if (pos != string::npos) {
        size_t start = content.find("\"", pos + 10);
        if (start != string::npos) {
            start++;
            size_t end = content.find("\"", start);
            if (end != string::npos) {
                string gppPath = content.substr(start, end - start);
                if (!gppPath.empty() && fs::exists(gppPath)) {
                    return gppPath;
                }
            }
        }
    }
    
    return "g++";
}

string getIncludePaths() {
    string includes = "";
    
    // Check if cpp_modules directory exists
    if (!fs::exists("cpp_modules")) {
        return includes;
    }
    
    // Check if cpp_package.json exists
    if (!fs::exists("cpp_package.json")) {
        // Fallback: scan cpp_modules for common include paths
        for (const auto& entry : fs::directory_iterator("cpp_modules")) {
            if (entry.is_directory()) {
                fs::path includeDir = entry.path() / "include";
                if (fs::exists(includeDir)) {
                    includes += "-I" + includeDir.string() + " ";
                }
            }
        }
        return includes;
    }
    
    // Parse cpp_package.json for include paths
    ifstream file("cpp_package.json");
    if (file) {
        string line, content;
        while (getline(file, line)) {
            content += line;
        }
        
        // Simple parsing for "include" fields
        size_t pos = 0;
        while ((pos = content.find("\"include\"", pos)) != string::npos) {
            size_t start = content.find("\"", pos + 9);
            if (start != string::npos) {
                start++;
                size_t end = content.find("\"", start);
                if (end != string::npos) {
                    string includePath = content.substr(start, end - start);
                    includes += "-I" + includePath + " ";
                }
            }
            pos++;
        }
    }
    
    return includes;
}

int main(int argc, char* argv[]) {
    // Check for config command
    if (argc >= 2 && string(argv[1]) == "config") {
        string configCmd = "powershell -ExecutionPolicy Bypass -File gwrap_config.ps1";
        
        // Pass additional arguments
        for (int i = 2; i < argc; i++) {
            configCmd += " -";
            if (i == 2) {
                configCmd += "Action \"" + string(argv[i]) + "\"";
            } else if (i == 3) {
                configCmd += "Tool \"" + string(argv[i]) + "\"";
            } else if (i == 4) {
                configCmd += "Path \"" + string(argv[i]) + "\"";
            }
        }
        
        int ret = system(configCmd.c_str());
        return ret;
    }
    
    // Check for install command
    if (argc >= 3 && string(argv[1]) == "install") {
        string package = argv[2];
        
        cout << "Installing " << package << " using vcpkg..." << endl;
        
        // Build PowerShell command to run vcpkg_install.ps1
        string installCmd = "powershell -ExecutionPolicy Bypass -File vcpkg_install.ps1 -Package \"" + package + "\"";
        
        int ret = system(installCmd.c_str());
        
        if (ret == 0) {
            cout << "\nPackage installed successfully!" << endl;
            cout << "Rebuild gwrap to use the new package:" << endl;
            cout << "  g++ -std=c++17 -O2 gwrap.cpp -o gwrap.exe" << endl;
        } else {
            cout << "Installation failed. Check the output above for errors." << endl;
        }
        
        return ret;
    }
    
    // Check for update command
    if (argc >= 2 && string(argv[1]) == "update") {
        cout << "Checking for package updates..." << endl;
        
        // Build PowerShell command to run vcpkg_update.ps1
        string updateCmd = "powershell -ExecutionPolicy Bypass -File vcpkg_update.ps1";
        
        int ret = system(updateCmd.c_str());
        
        return ret;
    }
    
    // Original g++ forwarding behavior
    string gppPath = getGppPath();
    string cmd = "\"" + gppPath + "\" ";
    
    // Check if this is a compilation/linking command (not just --version, -E, etc.)
    bool isCompilation = false;
    for(int i = 1; i < argc; i++) {
        string arg = argv[i];
        // If we see source files (.cpp, .c, .cc, .cxx) or -c flag, it's compilation
        if (arg.find(".cpp") != string::npos || 
            arg.find(".cc") != string::npos || 
            arg.find(".cxx") != string::npos || 
            arg.find(".c") != string::npos ||
            arg == "-c" || arg == "-o") {
            isCompilation = true;
            break;
        }
    }
    
    // Only add include paths if this is actual compilation
    if (isCompilation) {
        string includePaths = getIncludePaths();
        cmd += includePaths;
    }
    
    // Add user arguments
    for(int i = 1; i < argc; i++) {
        cmd += argv[i];
        if(i != argc - 1) 
            cmd += " ";
    }
    
    int ret = system(cmd.c_str());
    return ret;
}
