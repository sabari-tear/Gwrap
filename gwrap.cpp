#include <iostream>
#include <string>
#include <cstdlib>
using namespace std;
int main(int argc, char* argv[]) {
    string cmd = "g++ ";
    for(int i = 1; i < argc; i++) {
        cmd += argv[i];
        if(i != argc - 1) 
            cmd += " ";
    }
    int ret = system(cmd.c_str());
    return ret;
}