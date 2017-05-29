//
//  MemoryUploader.h
//  RealityEditor
//
//  Created by James Hobin on 7/19/16.
//
//

#ifndef MemoryUploader_h
#define MemoryUploader_h

#include <memory>

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
#include "ImagePartSource.h"
#include "QCARState.h"

using namespace std;
using namespace Poco;
using namespace Poco::Net;

class MemoryUploader : public Poco::Runnable {
public:
    MemoryUploader(string _objId, string _ip, shared_ptr<QCARState> _memory);
    virtual void run();
    bool done;
private:
    // See also realityEditor.h thumbnailWidth and thumbnailHeight
    const int thumbnailWidth = 134;
    const int thumbnailHeight = 75;
    shared_ptr<QCARState> memory;
    string ip, objId;
    
};

#endif /* MemoryUploader_h */
