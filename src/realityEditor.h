#pragma once

//#include "ofMain.h"
//#include "ofxiOS.h"
//#include "ofxiOSExtras.h"

#include "ofxQCAR.h"
#include "ofxJSON.h"
#include "ofxNetwork.h"
#include "ofxUIWebViewInterfaceJavaScript.h"
#include "ofxXmlSettings.h"

class realityEditor : public ofxQCAR_App, ofxUIWebViewDelegateCpp { // 

public:
    void setup();

    void update();

    void draw();

    void exit();

    void renderJavascript();

    void downloadTargets();

    void cons();

    void urlResponse(ofHttpResponse &response);
    

    ofxUDPManager udpConnection, udpConnection2;
    // HeartbeatListener* heartbeatListener;
    vector<vector<string> > nameCount;

    ofxUIWebViewInterfaceJavaScript interface;

    void handleCustomRequest(NSString *request);

    ofxJSONElement json;
    bool waitUntil;
    bool onlyOnce;
    bool waitGUI;
    char udpMessage[256];
    bool nameExists = false;
    
    ofxXmlSettings XML;
    	string xmlStructure;

    ofHttpResponse ofSaveURLTo(string url, string path);

    ofBuffer dataBuffer;

    ofMatrix4x4 tempMatrix;
    vector<ofMatrix4x4> matrixTemp;
    vector<string> nameTemp;

    int foundMarker;
    bool reloader = false;
    bool freeze = false;
        bool extendedTracking = false;
    bool frozeCameraImage = false;
    float cameraRatio = 1;
    
    ofFbo fbo;
    ofFbo fbo2;

    ofImage cameraImage;

    ofImage imgInterface, imgObject;
    // NSMutableString *stringforTransform;

    //vector<ofxQCAR_Marker>tempMarker;
    bool projectionMatrixSend = false;

    NSString *pMatrix;

    NSMutableString *stringforTransform = [NSMutableString stringWithCapacity:1000];

    ofAppiOSWindow thisWindow =  *ofxiPhoneGetOFWindow();
    int screenScale = 1;
    
    int haveChangedUIwithURL = 0;
    bool changedURLOk = false;
    
    
   int developerState = 0;
   int extTrackingState = 0;
   int clearSkyState = 0;
   string externalState = "";

    /* void touchDown(ofTouchEventArgs & touch);
     void touchMoved(ofTouchEventArgs & touch);
     void touchUp(ofTouchEventArgs & touch);
     void touchDoubleTap(ofTouchEventArgs & touch);
     void touchCancelled(ofTouchEventArgs & touch);*/

    /*  void lostFocus();
      void gotFocus();
      void gotMemoryWarning();
      void deviceOrientationChanged(int newOrientation);*/

};


