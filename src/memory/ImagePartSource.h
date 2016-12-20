//
//  ImagePartSource.h
//  RealityEditor
//
//  Created by James Hobin on 7/14/16.
//
//

#ifndef ImagePartSource_h
#define ImagePartSource_h

#include "ofMain.h"
#include "ofxiOs.h"
#include "Poco/Net/Net.h"
#include "Poco/Net/PartSource.h"

using namespace std;
using namespace Poco::Net;


// http://stackoverflow.com/questions/7781898/get-an-istream-from-a-char
class membuf : public streambuf {
public:
    membuf() {
    }
    
    void setData(char* begin, char* end) {
        setg(begin, begin, end);
    }
};

class ImagePartSource : public PartSource {
public:
    ImagePartSource(ofImage image);
    
    istream& stream();
    
    const string& filename() const;
    
    streamsize getContentLength() const;

    ~ImagePartSource();
private:
    const string _filename = "memory.jpg";
    membuf _str;
    ofBuffer _buf;
    istream* _in;
};


#endif /* ImagePartSource_h */
