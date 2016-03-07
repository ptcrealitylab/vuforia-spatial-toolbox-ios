#pragma once

//#include "ofMain.h"
//#include "ofxiOS.h"
//#include "ofxiOSExtras.h"

#include "ofxQCAR.h"
#include "ofxJSON.h"
#include "ofxNetwork.h"
#include "ofxXmlSettings.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
#include "ofxWKWebViewInterfaceJavaScript.h"
#else
#include "ofxUIWebViewInterfaceJavaScript.h"
#endif


#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
class realityEditor : public ofxQCAR_App, ofxWKWebViewDelegateCpp {
#else
class realityEditor : public ofxQCAR_App, ofxUIWebViewDelegateCpp {
#endif

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

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
    ofxWKWebViewInterfaceJavaScript interface;
#else
    ofxUIWebViewInterfaceJavaScript interface;
#endif

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
    
    bool sendAccelerationData = false;
    
    ofVec3f accel;
    ofVec2f orientation;


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


