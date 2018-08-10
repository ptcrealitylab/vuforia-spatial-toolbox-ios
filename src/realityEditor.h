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
 * Created by Valentin Heun on 4/4/13.
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

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxQCAR.h"
#include "ofxJSON.h"
#include "ofxNetwork.h"
#include "ofxXmlSettings.h"

#import <Vuforia/CameraCalibration.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Tool.h>
#import <Vuforia/Matrices.h>

#include "ofxWebViewInterface.h"
#include "SpeechInterface.h"

#include "Poco/Base64Encoder.h"
#include "Poco/ThreadPool.h"
#include "Poco/URI.h"

#include "ImagePartSource.h"
#include "QCARState.h"
#include "MemoryUploader.h"

#include "ofxiOSVideoWriter.h"
#import "REVideoWriterDelegate.h"
#include "VideoUploader.h"

class realityEditor : public ofxQCAR_App, ofxWebViewDelegateCpp, SpeechDelegateCpp {
public:
    void setup();

    void update();

    void draw();

    void deviceOrientationChanged(int newOrientation);

    void exit();

    void renderJavascript();

    bool processSingleHeartBeat(string udpMessage, string address);

    void downloadTargets();

    void cons();

    void urlResponse(ofHttpResponse &response);

    ofFile files_;
    ofxUDPManager udpConnection, udpConnection2;
    // HeartbeatListener* heartbeatListener;
    // 0 -> name/id
    // 1 -> ip
    // 2 -> version
    // 3 -> TCS
    // 4 -> state thing
    // 5 -> state thing
    // 6 -> state thing
    // 7 -> state thing
    vector<vector<string> > nameCount;
    vector<vector<string> > targetsList;
    
    // new javascript API endpoints
    void getDeviceReady(string cb);
    void getVuforiaReady(string cb);
    void addNewMarker(string markerName, string cb);
    void getProjectionMatrix(string cb);
    void getMatrixStream(string cb);
    void getScreenshot(string size, string cb);
    void setPause();
    void setResume();
    void getUDPMessages(string cb);
    void sendUDPMessage(string message);
    void getFileExists(string fileName, string cb);
    void downloadFile(string fileName, string cb);
    void getFilesExist(vector<string> fileNameArray, string cb);
    void getChecksum(vector<string> fileNameArray, string cb);
    void setStorage(string storageID, string message);
    void getStorage(string storageID, string cb);
    void startSpeechRecording();
    void stopSpeechRecording();
    void addSpeechListener(string cb);
    // old requests
    void kickoff();
    void reload();
    void oldUI();
    void sendAccelerationData();
    void developerOn();
    void developerOff();
    void clearSkyOn();
    void clearSkyOff();
    void realityOn();
    void realityOff();
    void instantOn();
    void instantOff();
    void zoneOn();
    void zoneOff();
    void tap();
    void extendedTrackingOn();
    void extendedTrackingOff();
    void createMemory();
    void clearMemory();
    void loadNewUI(string reloadURL);
    void setDiscovery(string discoveryURL);
    void removeDiscovery();
    void memorize();
    void remember(string dataStr);
    void authenticateTouch();
    void startVideoRecording(string objectKey, string objectMatrix);
    void stopVideoRecording(string objectMatrix);
    
    void callJavaScriptCallback(string cb);
    void callJavaScriptCallback(string cb, NSString* arg1);
    
    void clearCache();
    
    SpeechInterfaceCpp speechInterface;
    void handleIncomingSpeech(std::string bestTranscription);
    
    string speechCallback;
    string matrixStreamCallback;
    string udpCallback;

    ofxWebViewInterfaceJavaScript interface;
    void handleCustomRequest(NSDictionary *messageBody);
    
    virtual void qcarInitARDone(NSError *error);
    bool qCARInitARDone = false;

    ofxJSONElement json;
    ofxJSONElement allObjectJSON;
    bool waitUntil;
    bool onlyOnce;
    bool waitGUI;
    char udpMessage[256];
    bool nameExists = false;
    bool targetExists = false;
    bool allTargetsExist = false;
    int numbersToMuch;

    string arrayList[3] = {"dat", "xml", "jpg"};

    int datasetHolder = 100000;

    ofxXmlSettings XML;
    ofxXmlSettings XMLTargets;

    int interfaceCounter = 0;
    string xmlStructure;

    ofHttpResponse ofSaveURLTo(string url, string path);

    ofBuffer dataBuffer;

    ofMatrix4x4 tempMatrix;

    vector<ofMatrix4x4> matrixTemp;
    vector<string> nameTemp;

    shared_ptr<QCARState> currentMemory = nullptr;

    vector<Vuforia::DataSet *>  datasetList;

    float matrixOld = 0.0;

    int foundMarker;
    bool reloader = false;
    bool extendedTracking = false;
    float cameraRatio = 1;

    bool updateSwitch =true;

    ofImage imgInterface, imgObject;
    // NSMutableString *stringforTransform;

    //vector<ofxQCAR_Marker>tempMarker;

    NSString *pMatrix;

    NSMutableString *stringforTransform = [NSMutableString stringWithCapacity:2000];

    ofAppiOSWindow thisWindow =  *ofxiPhoneGetOFWindow();
    int screenScale = 1;

    int haveChangedUIwithURL = 0;
    bool changedURLOk = false;

    int developerState = 0;
    int extTrackingState = 0;
    int clearSkyState = 0;
    int realityState = 0;
    int instantState = 1;
    
    string externalState = "";
    string discoveryState = "";
     string zoneText = "";
      int zoneState = 0;
    bool tcpDiscovery = false;


    bool shouldSendAccelerationData = false;

    ofVec3f accel;
    ofVec2f orientation;
    bool inSync = false;

    bool everySecond = false;

    string lastTracker;

    int32_t crc32(const void* data, size_t length);
    long bitNumber (bool bits[21]);
    string itob62( long i );
    uint32_t crc = 0xffffffff;
    void crc32reset();

    ofFile file;
    ofBuffer buff;

    // The memory that will be made permanent by memorize() or thrown away by clearMemory()
    shared_ptr<QCARState> tempMemory;

    // A thread pool used for executing memory uploading off the main thread
    Poco::ThreadPool memoryThreadPool;
    shared_ptr<MemoryUploader> memoryUploader;
    
    Poco::ThreadPool videoThreadPool;
    shared_ptr<VideoUploader> videoUploader;

    const int thumbnailWidth = 200;
    const int thumbnailHeight = 112;

    ofImage getCameraImage();
    void sendThumbnail(shared_ptr<QCARState> memory);
    void uploadMemory(shared_ptr<QCARState> memory);
    void uploadVideo(NSURL* videoPath);
    NSString* convertImageToBase64(ofImage image);
    bool getDataFromReq(string req, string reqName, string* data);

    NSString* stringFromMatrix(ofMatrix4x4 mat);
    void sendProjectionMatrix();

    string getName(string objectId);

    /* void touchDown(ofTouchEventArgs & touch);
     void touchMoved(ofTouchEventArgs & touch);
     void touchUp(ofTouchEventArgs & touch);
     void touchDoubleTap(ofTouchEventArgs & touch);
     void touchCancelled(ofTouchEventArgs & touch);*/

    /*  void lostFocus();
     void gotFocus();
     void gotMemoryWarning();
     void deviceOrientationChanged(int newOrientation);*/
    
    ofxiOSVideoWriter videoWriter;
    bool bRecord;
    string recordingObjectKey;
    string recordingObjectStartMatrix;
    string recordingObjectVideoId;
    REVideoWriterDelegate* videoWriterDelegate;
    
//    bool bRecordChanged;
//    bool bRecordReadyToStart;
//
//    ofxiOSVideoPlayer videoPlayer0;
//
//    ofMesh box;
//    ofFloatColor c1;
//    ofFloatColor c2;
//    ofFloatColor c3;
//    vector<ofVec2f> points;
//    vector<ofVec2f> pointsNew;
//
//    ofxToggle recordToggle;
    
};


