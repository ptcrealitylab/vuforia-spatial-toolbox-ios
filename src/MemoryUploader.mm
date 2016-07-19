//
//  MemoryUploader.m
//  RealityEditor
//
//  Created by James Hobin on 7/19/16.
//
//

#include "MemoryUploader.h"

MemoryUploader::MemoryUploader(string _objId, string _ip, shared_ptr<VuforiaState> _memory) {
    objId = _objId;
    ip = _ip;
    memory = _memory;
    done = false;
}

void MemoryUploader::run() {
    // Adapted from a stackoverflow response
    HTTPRequest request(HTTPRequest::HTTP_POST, "/object/" + objId + "/memory", HTTPMessage::HTTP_1_1);

    HTMLForm form;
    form.setEncoding(HTMLForm::ENCODING_MULTIPART);

    ofxJSONElement memoryInfo;
    for (int i = 0; i < 16; i++) {
        memoryInfo["matrix"][i] = memory->matrix[0]._mat[i / 4][i % 4];
    }

    form.set("memoryInfo", memoryInfo.getRawString());
    form.addPart("memoryImage", new ImagePartSource(memory->image));
    form.prepareSubmit(request);

    HTTPClientSession httpSession(ip, 8080);
    httpSession.setTimeout(Timespan(20, 0));
    form.write(httpSession.sendRequest(request));

    HTTPResponse res;
    istream &is = httpSession.receiveResponse(res);
    StreamCopier::copyStream(is, std::cout);
    done = true;
}