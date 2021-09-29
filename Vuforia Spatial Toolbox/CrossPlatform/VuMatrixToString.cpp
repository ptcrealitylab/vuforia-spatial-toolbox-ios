//
//  VuMatrixToString.cpp
//  vst-swift
//
//  Created by Ben Reynolds on 9/15/21.
//

#include "VuMatrixToString.h"

const char* floatToString(char array[], float num) {
//    char array[10];
    sprintf(array, "%f", num);
    return array;
}

std::string vuMatrix44fToString(VuMatrix44F& matrix)
{
    std::string result = "[";

    for (int i = 0; i < 16; i++) {
        float val = matrix.data[i];
        char array[16]; // each string can be up to 16 characters long
        result += floatToString(array, val);
        if (i < 15) {
            result += ",";
        }
    }
    
    result += "]";
    
    return result;
}
