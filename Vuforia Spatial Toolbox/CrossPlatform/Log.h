 /*===============================================================================
 Copyright (c) 2020, PTC Inc. All rights reserved.
  
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

 #ifndef __LOG_H__
 #define __LOG_H__

 #include <stdio.h>

#define LOG_TAG "Vuforia"

 // Logging macros:

#if defined (__ANDROID__)
#include <android/log.h>
#   define LOG_TAG "Vuforia"
#   define LOG(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

#elif defined(WINAPI_FAMILY) // UWP
// Use logging method implemented in UWP/Log.cpp
void LOG(const char* message, ...);

#elif defined(__APPLE__) // iOS
#   define LOG(...) do { printf(__VA_ARGS__); printf("\n"); } while (0)
#endif

#endif // __LOG_H__
