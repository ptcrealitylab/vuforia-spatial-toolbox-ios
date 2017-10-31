//
//  javaScriptInterface.cpp
//  RealityEditor
//
//  Created by Valentin Heun on 10/24/17.
//

#include "javaScriptInterface.h"

void javaScriptInterface::adapter(string function) {
  /*  parseJavaScriptFunctionString(function, functionArg);
    
    if(functionArg[0] == "getVuforiaReady"){
        getVuforiaReady(functionArg[1]);
    }
   */
}


/*
Helper
 */

void javaScriptInterface::parseJavaScriptFunctionString(string function, string *arguments) {

    int functionCounter = 0;
    int argw = 0;
    int argi = 0;
    int oldPos = 0;
    
    // isolate function name and separate a string with all arguments
    if ((pos = function.find("(")) != std::string::npos) {
        arguments[0] = function.substr(0, pos);
        function.erase(0, pos + 1);
        function.erase(function.size() - 1); // erase last character
        argw++;
    }
    // separate arguments
    for (argi = 0; argi < function.size(); argi++) {
        // check if the argument is encapsulated
        if (function[argi] == "("[0] || function[argi] == "{"[0] || function[argi] == "["[0]) functionCounter++;
        if (function[argi] == ")"[0] || function[argi] == "}"[0] || function[argi] == "]"[0]) functionCounter--;
        if ((function[argi] == ","[0]) && (functionCounter <= 0)) {
            // check if there is a space after the comma
            arguments[argw] = function.substr(oldPos, argi - oldPos);

            for (int z = 0; function[argi + 1] == " "[0]; z++) {
                if (function[argi + z] >= function.size()) break;
                argi++;
            }
            oldPos = argi + 1;
            argw++;
        }
    }
    arguments[argw] = function.substr(oldPos, argi - oldPos);

  for (int i = 0; i < sizeof(arguments); i++) { cout << arguments[i] << "\n";}
    
}


