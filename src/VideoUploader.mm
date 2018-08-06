//
//  VideoUploader.m
//  Editor
//
//  Created by Benjamin Reynolds on 8/3/18.
//

#import "VideoUploader.h"

VideoUploader::VideoUploader(string _objId, string _ip, NSURL* _videoPath) {
    objId = _objId;
    ip = _ip;
    videoPath = _videoPath;
    done = false;
}

void VideoUploader::run() {
    // Adapted from a stackoverflow response
    HTTPRequest request(HTTPRequest::HTTP_POST, "/object/" + objId + "/video", HTTPMessage::HTTP_1_1);
    
    HTMLForm form;
    form.setEncoding(HTMLForm::ENCODING_MULTIPART);

    FilePartSource* videoFilePart = new FilePartSource([[videoPath relativePath] UTF8String]);

    form.addPart("videoFile", videoFilePart);
    
    form.prepareSubmit(request);
    
    HTTPClientSession httpSession(ip, 8080);
    httpSession.setTimeout(Timespan(20, 0));
    form.write(httpSession.sendRequest(request));
    
    HTTPResponse res;
    istream &is = httpSession.receiveResponse(res);
    StreamCopier::copyStream(is, std::cout);
    done = true;
}
