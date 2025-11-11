#include <iostream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

int main() {
    json j;
    j["message"] = "CMake + Gwrap working!";
    j["auto_includes"] = true;
    
    std::cout << j.dump(2) << std::endl;
    return 0;
}
