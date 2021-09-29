/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

#ifndef __MEMORY_STREAM_H__
#define __MEMORY_STREAM_H__

#include <istream>
#include <streambuf>

/// streambuf implementation where the buffer is in memory
class MemoryStreamBuf : public std::streambuf
{
public:
    MemoryStreamBuf(char const* base, size_t size)
    {
        char* p(const_cast<char*>(base));
        this->setg(p, p, p + size);
    }
};

/// istream implementation to read from a buffer in memory
class MemoryInputStream : virtual MemoryStreamBuf, public std::istream
{
public:
    MemoryInputStream(char const* base, size_t size)
        : MemoryStreamBuf(base, size)
        , std::istream(static_cast<std::streambuf*>(this)) {}
};

#endif // __MEMORY_STREAM_H__
