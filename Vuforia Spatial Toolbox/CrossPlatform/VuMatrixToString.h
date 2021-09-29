//
//  VuMatrixToString.hpp
//  vst-swift
//
//  Created by Ben Reynolds on 9/15/21.
//

#ifndef VuMatrixToString_hpp
#define VuMatrixToString_hpp

#include <VuforiaEngine/VuforiaEngine.h>
#include <stdio.h>

#include <iostream>
#include <string>

using std::cout; using std::cin;
using std::endl; using std::string;

std::string vuMatrix44fToString(VuMatrix44F& matrix);

#endif /* VuMatrixToString_hpp */
