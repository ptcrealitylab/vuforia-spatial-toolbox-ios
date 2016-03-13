#pragma once

//#include "ofMain.h"
//#include "ofxiOS.h"
//#include "ofxiOSExtras.h"

#include "ofxVuforia.h"
#include "ofxJSON.h"
#include "ofxNetwork.h"
#include "ofxXmlSettings.h"

//#include "ofxWKWebViewInterfaceJavaScript.h"
//#include "ofxUIWebViewInterfaceJavaScript.h"

#include "ofxWebViewInterface.h"

class realityEditor : public ofxVuforia_App, ofxWebViewDelegateCpp /*ofxWKWebViewDelegateCpp, ofxUIWebViewDelegateCpp*/ {

public:
    void setup();

    void update();

    void draw();
    
    void deviceOrientationChanged(int newOrientation);

    void exit();

    void renderJavascript();

    void downloadTargets();

    void cons();

    void urlResponse(ofHttpResponse &response);
    

    ofxUDPManager udpConnection, udpConnection2;
    // HeartbeatListener* heartbeatListener;
    vector<vector<string> > nameCount;

//    ofxWKWebViewInterfaceJavaScript interface;
//    ofxUIWebViewInterfaceJavaScript interface;
    
    ofxWebViewInterfaceJavaScript interface;

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
      float matrixOld = 0.0;

    int foundMarker;
    bool reloader = false;
    bool freeze = false;
        bool extendedTracking = false;
    bool frozeCameraImage = false;
    float cameraRatio = 1;
    
    ofFbo fbo;
    ofFbo fbo2;
    
   bool updateSwitch =true;

    ofImage cameraImage;

    ofImage imgInterface, imgObject;
    // NSMutableString *stringforTransform;

    //vector<ofxVuforia_Marker>tempMarker;
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
    
    bool sendAccelerationData = false;
    
    ofVec3f accel;
    ofVec2f orientation;
    bool inSync = false;
    
    bool everySecond = false;

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


