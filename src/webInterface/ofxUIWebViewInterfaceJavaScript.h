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
 * Created by Benjamin Reynolds on 7/14/16.
 *
 * Copyright (c) 2015 Valentin Heun
 *
 * All ascii characters above must be included in any redistribution.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#pragma once

//#include "ofMain.h"
//#include "ofxiPhoneExtras.h"
#include "ofxVuforia.h"
#include "ofxWebViewInterface.h"
#include "ofxUIWebViewDelegate.h"

/**
ofxUIWebViewInterface interfaces with EXACTLY ONE UIWebView instance.

ofxUIWebViewInterface supports 2-way communication with the HTML page it is rendering:

1. Application -> HTML/JS:
runJavaScriptFromString(NSString* script)

2. HTML/JS -> Application:
shouldStartLoadWithRequest() of the DELEGATE will be called whenever
window.location.href = "OF://<address>" is run in the javascript.

Therefore, the protocol is up to the interface programmer to define by defining a SUBCLASS of the
ofxUIWebViewDelegate.
*/
@class UIWebViewMultiInteractable;

class ofxUIWebViewInterfaceJavaScript {

public:
    ofxUIWebViewInterfaceJavaScript();

    ~ofxUIWebViewInterfaceJavaScript();

    /** 1. Initialize */
    void initialize(); // use default ofxUIWebViewDelegate: no custom request handling
    void initializeWithCustomDelegate(ofxUIWebViewDelegateCpp *delegate);

    /** 2. Load a URL or a local file to the webview */
    void loadURL(string url);

    void loadLocalFile(string path);

    /** 3. Activating and deactivating a webview */
    void activateView();

    void deactivateView();

    void toggleView();

    /** 4. Running JS code */
    void *runJavaScriptFromString(NSString *script);

    UIWebView *getUIWebViewInstance() {
        return uiWebViewInstance;
    };

private:
    bool isShowingView;
    UIWebView *uiWebViewInstance;

    ofAppiOSWindow thisWindow = *ofxiPhoneGetOFWindow();
    int screenScale = 1;
};
