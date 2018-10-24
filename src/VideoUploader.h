//
//  VideoUploader.h
//  Editor
//
//  Created by Benjamin Reynolds on 8/3/18.
//

#ifndef VideoUploader_h
#define VideoUploader_h

#import <Foundation/Foundation.h>

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxJSON.h"
#include "Poco/Net/FilePartSource.h"
#include "Poco/Net/HTTPClientSession.h"
#include "Poco/Net/HTTPResponse.h"
#include "Poco/Net/HTTPRequest.h"
#include "Poco/Net/HTMLForm.h"
#include "Poco/Runnable.h"
#include "Poco/StreamCopier.h"
#include "Poco/Timespan.h"
//#include "ImagePartSource.h"
//#include "QCARState.h"

using namespace std;
using namespace Poco;
using namespace Poco::Net;

class VideoUploader : public Poco::Runnable {
public:
    VideoUploader(string _objId, string _ip, NSURL* _videoPath, string _startMatrix, string _videoId);
    virtual void run();
    bool done;
private:
    // See also realityEditor.h thumbnailWidth and thumbnailHeight
//    const int thumbnailWidth = 134;
//    const int thumbnailHeight = 75;
//    shared_ptr<QCARState> memory;
    NSURL* videoPath;
    string ip, objId, startMatrix, videoId;
    
};

#endif /* VideoUploader_h */
