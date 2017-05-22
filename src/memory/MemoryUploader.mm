/**
 * @preserve
 *
 *                                      .,,,;;,'''..
 *                                  .'','...     ..',,,.
 *                                .,,,,,,',,',;;:;,.  .,l,
 *                               .,',.     ...     ,;,   :l.
 *                              ':;.    .'.:do;;.    .c   ol;'.
 *       ';;'                   ;.;    ', .dkl';,    .c   :; .'.',::,,'''.
 *      ',,;;;,.                ; .,'     .'''.    .'.   .d;''.''''.
 *     .oxddl;::,,.             ',  .'''.   .... .'.   ,:;..
 *      .'cOX0OOkdoc.            .,'.   .. .....     'lc.
 *     .:;,,::co0XOko'              ....''..'.'''''''.
 *     .dxk0KKdc:cdOXKl............. .. ..,c....
 *      .',lxOOxl:'':xkl,',......'....    ,'.
 *           .';:oo:...                        .
 *                .cd,      ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐    .
 *                  .l;     ║╣  │││ │ │ │├┬┘    '
 *                    'l.   ╚═╝─┴┘┴ ┴ └─┘┴└─   '.
 *                     .o.                   ...
 *                      .''''','.;:''.........
 *                           .'  .l
 *                          .:.   l'
 *                         .:.    .l.
 *                        .x:      :k;,.
 *                        cxlc;    cdc,,;;.
 *                       'l :..   .c  ,
 *                       o.
 *                      .,
 *
 *      ╦═╗┌─┐┌─┐┬  ┬┌┬┐┬ ┬  ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐  ╔═╗┬─┐┌─┐ ┬┌─┐┌─┐┌┬┐
 *      ╠╦╝├┤ ├─┤│  │ │ └┬┘  ║╣  │││ │ │ │├┬┘  ╠═╝├┬┘│ │ │├┤ │   │
 *      ╩╚═└─┘┴ ┴┴─┘┴ ┴  ┴   ╚═╝─┴┘┴ ┴ └─┘┴└─  ╩  ┴└─└─┘└┘└─┘└─┘ ┴
 *
 *
 * Created by James Hobin on 7/14/16.
 *
 * Copyright (c) 2015 Valentin Heun
 *
 * All ascii characters above must be included in any redistribution.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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
    ofImage thumbnailImage;
    thumbnailImage.clone(memory->image);
    
    thumbnailImage.resize(thumbnailWidth, thumbnailHeight);
    
    form.addPart("memoryThumbnailImage", new ImagePartSource(thumbnailImage));
    form.prepareSubmit(request);

    HTTPClientSession httpSession(ip, 8080);
    httpSession.setTimeout(Timespan(20, 0));
    form.write(httpSession.sendRequest(request));

    HTTPResponse res;
    istream &is = httpSession.receiveResponse(res);
    StreamCopier::copyStream(is, std::cout);
    done = true;
}
