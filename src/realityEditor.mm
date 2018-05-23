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

#include "realityEditor.h"

// You need a vuforia key from the vuforia developer portal (or from ofxQCAR) to compile this application.
// you can just replace vuforiaKey with the sting of your key.
// In that case you also want to remove #include "vuforiaKey.h".
// vuforiaKey.h is just a file that contains a vuforia key that is not synchronized with github.
#include "vuforiaKey.h"

string kLicenseKey = vuforiaKey;

 string networkNamespace = "realityEditor.network";
 string deviceNamespace = "realityEditor.device";
 string arNamespace = "realityEditor.gui.ar";
 string drawNamespace = "realityEditor.gui.ar.draw";
 string memoryNamespace = "realityEditor.gui.memory";

//--------------------------------------------------------------
void realityEditor::setup() {

    numbersToMuch = 500;

    ofSetFrameRate(60);
    ofSetVerticalSync(false);

    // ofxAccelerometer.setup();

    if( XML.loadFile(ofxiOSGetDocumentsDirectory() + "editor.xml") ){
        cout<< "editor.xml loaded from documents folder!";
    }else if( XML.loadFile("editor.xml") ){
        cout << "editor.xml loaded from data folder!";
    }else{
        cout << "unable to load editor.xml check data/ folder";
    }


    if( XMLTargets.loadFile(ofxiOSGetDocumentsDirectory() + "targets.xml") ){
        cout<< "targets.xml loaded from documents folder!";
    }else if( XMLTargets.loadFile("targets.xml") ){
        cout << "targets.xml loaded from data folder!";
    }else{
        XMLTargets.saveFile("targets.xml");
        cout << "unable to load targets.xml check data/ folder";
    }


    developerState = XML.getValue("SETUP:DEVELOPER", 0);
    extTrackingState = XML.getValue("SETUP:TRACKING", 0);
    clearSkyState = XML.getValue("SETUP:CLEARSKY", 0);
    instantState = XML.getValue("SETUP:INSTANT", 1);
    externalState = XML.getValue("SETUP:EXTERNAL", "");
    discoveryState = XML.getValue("SETUP:DISCOVERY", "");
      zoneText = XML.getValue("SETUP:ZONETEXT", "");
    zoneState =XML.getValue("SETUP:ZONE", 0);
    realityState = XML.getValue("SETUP:REALITY", 0);


    int numDragTags = XMLTargets.getNumTags("target");
    cout << numDragTags;



    if(numDragTags > numbersToMuch){

        cout <<"-------------- to many markers found. deleting oldest \t";

        for(int q = 0; q < numDragTags; q++){
            vector<string> row;
            row.push_back(XMLTargets.getValue("target:id", "", q));  //4
            row.push_back(XMLTargets.getValue("target:ip", "", q)); //5
            row.push_back(XMLTargets.getValue("target:vn", "0", q)); //6
            row.push_back(XMLTargets.getValue("target:tcs", "0", q)); //7
            targetsList.push_back(row);
        }

        int numbersToDelete = numDragTags-numbersToMuch;

        string tmpDir([NSTemporaryDirectory() UTF8String]);

        for(int q = 0; q < numbersToDelete; q++){

            if(ofFile::doesFileExist(tmpDir + targetsList[q][0] + ".jpg"))
                cout <<"-------------- file exists "<<endl;
            else  cout <<"-------------- file not found "<<endl;

            files_.removeFile(tmpDir + targetsList[q][0] + ".jpg");
            cout <<"-------------- removing file: "<< targetsList[q][0]  <<".jpg"<<endl;

            if(!files_.doesFileExist(tmpDir + targetsList[q][0] + ".jpg"))
                cout <<"-------------- success "<<endl;
            else
                cout <<"-------------- file still exists "<<endl;


            if(!files_.doesFileExist(tmpDir + targetsList[q][0] + ".xml"))
                cout <<"-------------- file not found "<<endl;
            else
                cout <<"-------------- file exists "<<endl;

            files_.removeFile(tmpDir + targetsList[q][0] + ".xml");
            cout <<"--------------  removing file: "<< targetsList[q][0]  <<".xml"<<endl;

            if(!files_.doesFileExist(tmpDir + targetsList[q][0] + ".xml"))
                cout <<"-------------- success "<<endl;
            else
                cout <<"-------------- file still exists "<<endl;


            if(!files_.doesFileExist(tmpDir + targetsList[q][0] + ".dat"))
                cout <<"-------------- file not found "<<endl;
            else
                cout <<"-------------- file exists "<<endl;

            files_.removeFile(tmpDir + targetsList[q][0] + ".dat");
            cout <<"--------------  removing file: "<< targetsList[q][0]  <<".dat" <<endl;
            if(!files_.doesFileExist(tmpDir + targetsList[q][0] + ".dat"))
                cout <<"-------------- success "<<endl;
            else
                cout <<"-------------- file still exists "<<endl;
        }



        XMLTargets.clear();

        for(int q = numbersToDelete; q < numDragTags; q++){
            int tagNum = XMLTargets.addTag("target");
            XMLTargets.setValue("target:id", targetsList[q][0], tagNum);
            XMLTargets.setValue("target:ip", targetsList[q][1], tagNum);
            XMLTargets.setValue("target:vn", targetsList[q][2], tagNum);
            XMLTargets.setValue("target:tcs", targetsList[q][3], tagNum);
        }
        XMLTargets.saveFile(ofxiOSGetDocumentsDirectory() + "targets.xml" );

    }

    ofBackground(150);

    // images for status in the editor
    imgInterface.load("interface.png");
    imgObject.load("object.png");

    imgObject.draw(20, 20);

    // variables for status
    waitUntil = false;
    onlyOnce = true;
    waitGUI = false;

    // clear temporary folder
    /* NSArray *tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
     for (NSString *file in tmpDirectory) {
     [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
     }*/

    // initialize QCAR
    ofxQCAR & QCAR = *ofxQCAR::getInstance();
    QCAR.setLicenseKey(kLicenseKey); // ADD YOUR APPLICATION LICENSE KEY HERE.
    QCAR.addMarkerDataPath("target.xml");
    QCAR.autoFocusOn();
    QCAR.setOrientation(OFX_QCAR_ORIENTATION_LANDSCAPE);
    QCAR.setCameraPixelsFlag(true);
    QCAR.setMaxNumOfMarkers(5);
    QCAR.setup();
    
    if(extTrackingState){
        ofxQCAR & QCAR = *ofxQCAR::getInstance();
        QCAR.startExtendedTracking();
        extendedTracking = true;
    }else{
        ofxQCAR & QCAR = *ofxQCAR::getInstance();
        QCAR.stopExtendedTracking();
        extendedTracking = false;

    }

    //usleep(5000000);


    interface.initializeWithCustomDelegate(this);
    speechInterface.initializeWithCustomDelegate(this);

    if(discoveryState !=""){

        cout << "activate object discovery server: " << externalState;
         tcpDiscovery = false;





        if (discoveryState.rfind("http://", 0) != 0 && discoveryState != "http")
        {
            discoveryState = "http://"+discoveryState;
            tcpDiscovery = true;
        } else if (discoveryState.rfind("http://", 0) == 0 || discoveryState.rfind("https://", 0) == 0){
            tcpDiscovery = true;
        }


    }



    if(externalState !="" && externalState !="http"){

        cout << "loading interface from: " << externalState;
        
       

        if (externalState.rfind("http://", 0) != 0 && externalState != "http")
        {
            externalState = "http://"+externalState;
        }



        interface.loadURL(externalState.c_str());
        interface.activateView();
        haveChangedUIwithURL = 500;
    }else{


        /**********************************************
         INITIALIZING THE INTERFACE
         **********************************************/

//        interface.loadLocalFile("index");
        interface.loadInterfaceFromLocalServer();
        //   interface.loadURL("http://html5test.com");

        interface.activateView();

    }

    ofLog()<<"**+++***++***+: "<< ofGetWindowSize() ;

    ofLog()<<"**+++***++***+: "<< ofGetWindowHeight() ;
    ofLog()<<"**+++***++***+: "<< ofGetWindowWidth() ;



    if(thisWindow.isRetinaEnabled()){
        screenScale =2;
    }
    usleep(100000);
}

#pragma mark - Speech Recognition

void realityEditor::handleIncomingSpeech(std::string bestTranscription) {
    cout << "realityEditor did receive speech: " << bestTranscription << endl;
    if (!speechCallback.empty()) {
        NSString *jsString =[NSString stringWithFormat:@"%s", speechCallback.c_str()];
        NSString *arg1String =[NSString stringWithFormat:@"'%s'", bestTranscription.c_str()];

        NSString *jsStringWithArgs = [jsString stringByReplacingOccurrencesOfString:@"__ARG1__" withString:arg1String];
        
        cout << " output: "<< jsStringWithArgs;
        interface.runJavaScriptFromString(jsStringWithArgs);
    }
}

#pragma mark - Routes to handle function calls from JavaScript

/**********************************************
 (new method for) HANDLING REQUESTS FROM JS/HTML (JS->C++)
 **********************************************/
void realityEditor::handleCustomRequest(NSDictionary *messageBody) {
    NSLog(@"message body: %@", messageBody);
    
    string functionName = [messageBody[@"functionName"] UTF8String];
    NSDictionary* arguments = messageBody[@"arguments"];
    NSString* callback = messageBody[@"callback"];
    string cb = "";
    if (callback != nil) {
        cb = [callback UTF8String];
    }
    
    if (functionName == "getDeviceReady") {
        getDeviceReady(cb);
        
    } else if (functionName == "getVuforiaReady") {
        getVuforiaReady(cb);
    
    } else if (functionName == "addNewMarker") {
        string markerName = [(NSString *)arguments[@"markerName"] UTF8String];
        addNewMarker(markerName, cb);
        
    } else if (functionName == "getProjectionMatrix") {
        getProjectionMatrix(cb);
        
    } else if (functionName == "getMatrixStream") {
        getMatrixStream(cb);
        
    } else if (functionName == "getScreenshot") {
        string size = [(NSString *)arguments[@"size"] UTF8String];
        getScreenshot(size, cb);
        
    } else if (functionName == "setPause") {
        setPause();
        
    } else if (functionName == "setResume") {
        setResume();
        
    } else if (functionName == "getUDPMessages") {
        getUDPMessages(cb);
        
    } else if (functionName == "sendUDPMessage") {
        string message = [(NSString *)arguments[@"message"] UTF8String];
        sendUDPMessage(message);
        
    } else if (functionName == "getFileExists") {
        string fileName = [(NSString *)arguments[@"fileName"] UTF8String];
        getFileExists(fileName, cb);
        
    } else if (functionName == "downloadFile") {
        string fileName = [(NSString *)arguments[@"fileName"] UTF8String];
        downloadFile(fileName, cb);
        
    } else if (functionName == "getFilesExist") {
        vector<string> fileNameArray;
        NSArray* fileNames = (NSArray *)arguments[@"fileNameArray"];
        for (NSString* fileName in fileNames) {
            fileNameArray.push_back([fileName UTF8String]);
        }
        getFilesExist(fileNameArray, cb);
        
    } else if (functionName == "getChecksum") {
        vector<string> fileNameArray;
        NSArray* fileNames = (NSArray *)arguments[@"fileNameArray"];
        for (NSString* fileName in fileNames) {
            fileNameArray.push_back([fileName UTF8String]);
        }
        getChecksum(fileNameArray, cb);
        
    } else if (functionName == "setStorage") {
        string storageID = [(NSString *)arguments[@"storageID"] UTF8String];
        string message = [(NSString *)arguments[@"message"] UTF8String];
        setStorage(storageID, message);
        
    } else if (functionName == "getStorage") {
        string storageID = [(NSString *)arguments[@"storageID"] UTF8String];
        getStorage(storageID, cb);
        
    } else if (functionName == "startSpeechRecording") {
        startSpeechRecording();
        
    } else if (functionName == "stopSpeechRecording") {
        stopSpeechRecording();
        
    } else if (functionName == "addSpeechListener") {
        addSpeechListener(cb);
        
    }
    /***** OLD REQUESTS *****/

      else if (functionName == "kickoff") {
        kickoff();
        
    } else if (functionName == "reload") {
        reload();
        
    } else if (functionName == "oldUI") {
        oldUI();
        
    } else if (functionName == "freeze") {
        freeze();
        
    } else if (functionName == "unfreeze") {
        unfreeze();
        
    } else if (functionName == "sendAccelerationData") {
        sendAccelerationData();
        
    } else if (functionName == "developerOn") {
        developerOn();
        
    } else if (functionName == "developerOff") {
        developerOff();
        
    } else if (functionName == "clearSkyOn") {
        clearSkyOn();
        
    } else if (functionName == "clearSkyOff") {
        clearSkyOff();
        
    } else if (functionName == "realityOn") {
        realityOn();
        
    } else if (functionName == "realityOff") {
        realityOff();
        
    } else if (functionName == "instantOn") {
        instantOn();
        
    } else if (functionName == "instantOff") {
        instantOff();
        
    } else if (functionName == "extendedTrackingOn") {
        extendedTrackingOn();
        
    } else if (functionName == "extendedTrackingOff") {
        extendedTrackingOff();
        
    } else if (functionName == "zoneText") {
          zoneText = [(NSString *)arguments[@"zoneText"] UTF8String];
        XML.setValue("SETUP:ZONETEXT", zoneText);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
        
    } else if (functionName == "zoneOn") {
   zoneOn();
    } else if (functionName == "zoneOff") {
    zoneOff();
    } else if (functionName == "tap") {
        tap();
    } else if (functionName == "createMemory") {
        createMemory();
        
    } else if (functionName == "clearMemory") {
        clearMemory();
        
    } else if (functionName == "loadNewUI") {
        string reloadURL = [(NSString *)arguments[@"reloadURL"] UTF8String];
        loadNewUI(reloadURL);
        
    } else if (functionName == "setDiscovery") {
        string discoveryURL = [(NSString *)arguments[@"discoveryURL"] UTF8String];
        setDiscovery(discoveryURL);
        
    } else if (functionName == "removeDiscovery") {
        removeDiscovery();
        
    } else if (functionName == "memorize") {
        memorize();
        
    } else if (functionName == "remember") {
        string dataStr = [(NSString *)arguments[@"dataStr"] UTF8String];
        remember(dataStr);
        
    } else if (functionName == "authenticateTouch") {
        authenticateTouch();
    
    } else if (functionName == "clearCache") {
        clearCache();
    }
    
}

#pragma mark - START OF Functions Called From JavaScript
#pragma mark -

void realityEditor::getDeviceReady(string cb){   }

void realityEditor::getVuforiaReady(string cb) {
    cout << "-------------------" << "\n";
    cout << cb << "\n";
    cout << "-------------------" << "\n";
    NSString *jsString44 =[NSString stringWithFormat:@"%s", cb.c_str()];
    cout << " output: "<< jsString44;
    interface.runJavaScriptFromString(jsString44);
}

void realityEditor::addNewMarker(string markerName, string cb){   }
void realityEditor::getProjectionMatrix(string cb){   }
void realityEditor::getMatrixStream(string cb){   }
void realityEditor::getScreenshot(string size, string cb){   }
void realityEditor::setPause(){   }
void realityEditor::setResume(){   }
void realityEditor::getUDPMessages(string cb){   }
void realityEditor::sendUDPMessage(string message){   }
void realityEditor::getFileExists(string fileName, string cb){   }
void realityEditor::downloadFile(string fileName, string cb){   }
void realityEditor::getFilesExist(vector<string> fileNameArray, string cb){   }
void realityEditor::getChecksum(vector<string> fileNameArray, string cb){   }
void realityEditor::setStorage(string storageID, string message){   }
void realityEditor::getStorage(string storageID, string cb){   }

void realityEditor::startSpeechRecording(){
    speechInterface.startRecording();
}

void realityEditor::stopSpeechRecording(){
    speechCallback = "";
    speechInterface.stopRecording();
}

void realityEditor::addSpeechListener(string cb){
    speechCallback = cb;
    cout << "-------------------" << "\n";
    cout << "set speechCallback: " << speechCallback << "\n";
    cout << "-------------------" << "\n";
}

/***** OLD REQUESTS *****/

// if the html interface is loaded kickoff will be send to the c++ code.
void realityEditor::kickoff() {
    waitUntil = true;
    NSLog(@"kickoff");
    
    if(haveChangedUIwithURL > 0){
        // reloader = true;
        changedURLOk = true;
        // here is where we need to write the permanent link saving mechanism
    }
    
    if (qCARInitARDone) {
        sendProjectionMatrix();
    }
    
    // help to reestablish the arrays when reloaded the interface
    // needs some more work on getting back and forth all the different objects
    
    
    // if the message is reload then the interface reloads and all objects are resent to the editor
    
    // always reset speech recording to off when loading app (prevents bug)
    int speechState = 0;
    
    NSString *stateSender = [NSString stringWithFormat:@"%s.setStates(%d, %d, %d, %d, %d, \"%s\", \"%s\", %d,\"%s\", %d )",
                             deviceNamespace.c_str(),
                             developerState,
                             extTrackingState,
                             clearSkyState,
                             instantState,
                             speechState,
                             externalState.c_str(),
                             discoveryState.c_str(),
                             realityState, zoneText.c_str(), zoneState];
    interface.runJavaScriptFromString(stateSender);
    
    NSString *deviceSender = [NSString stringWithFormat:@"%s.setDeviceName(\"%s\")",
                              deviceNamespace.c_str(),
                              ofxiOSGetDeviceRevision().c_str()];
    interface.runJavaScriptFromString(deviceSender);
    
    //  NSLog(stateSender);
    
    
    // if (reloader == true) {
    
    
    cout<< "---->>>---<<<---Sending reload";
    
    
    for (int i = 0; i < nameCount.size(); i++) {
        cout<<&nameCount[i];
        if(nameCount[i][0] != "allTargetsPlaceholder000000000000"){
            NSString *jsString3 = [NSString stringWithFormat:@"%s.addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})",
                                   networkNamespace.c_str(),
                                   nameCount[i][0].c_str(),
                                   nameCount[i][1].c_str(),
                                   stoi(nameCount[i][2].c_str()),
                                   nameCount[i][3].c_str()];
            interface.runJavaScriptFromString(jsString3);
        }
        //   NSLog(@"reload interfaces");
    }
    //}
    NSLog(@"reload interfaces");
}

void realityEditor::reload() {
    waitUntil = false;
    
    if(externalState !=""){
        interface.deactivateView();
        
        if (externalState.rfind("http://", 0) != 0 && externalState != "http")
        {
            externalState = "http://"+externalState;
        }
        
        interface.loadURL(externalState.c_str());
        interface.activateView();
    }else{
        interface.deactivateView();
//        interface.loadLocalFile("index");
        interface.loadInterfaceFromLocalServer();
        interface.activateView();
    }
    
    //reloader = true;
    NSString *stateSender = [NSString stringWithFormat:@"%s.setStates(%d, %d, %d, %d, \"%s\", \"%s\", %d)",
                             deviceNamespace.c_str(),
                             developerState,
                             extTrackingState,
                             clearSkyState,
                             instantState,
                             externalState.c_str(),
                             discoveryState.c_str(),
                             realityState];
    interface.runJavaScriptFromString(stateSender);
}

void realityEditor::oldUI() {
    networkNamespace = "this";
    deviceNamespace = "this";
    arNamespace = "this";
    drawNamespace = "this";
    memoryNamespace = "this";
}

void realityEditor::freeze() {
    currentMemory = shared_ptr<QCARState>(new QCARState(getCameraImage(), matrixTemp, nameTemp));
}

void realityEditor::unfreeze() {
    currentMemory = nullptr;
}

void realityEditor::sendAccelerationData() {
    shouldSendAccelerationData = true;
}

void realityEditor::developerOn() {
    XML.setValue("SETUP:DEVELOPER", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::developerOff() {
    XML.setValue("SETUP:DEVELOPER", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::clearSkyOn() {
    XML.setValue("SETUP:CLEARSKY", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::clearSkyOff() {
    XML.setValue("SETUP:CLEARSKY", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::realityOn() {
    XML.setValue("SETUP:REALITY", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::realityOff() {
    XML.setValue("SETUP:REALITY", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::instantOn() {
    XML.setValue("SETUP:INSTANT", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::instantOff() {
    XML.setValue("SETUP:INSTANT", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::zoneOn() {
    XML.setValue("SETUP:ZONE", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
    zoneState = 1;
}

void realityEditor::zoneOff() {
    XML.setValue("SETUP:ZONE", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
    zoneState = 0;
}

void realityEditor::tap() {
    if([[UIDevice currentDevice].model isEqualToString:@"iPhone"])
    {
        AudioServicesPlaySystemSound (1519); //works ALWAYS as of this post
    }
    else
    {
        // Not an iPhone, so doesn't have vibrate
        // play the less annoying tick noise or one of your own
        AudioServicesPlayAlertSound (1105);
    }
}

void realityEditor::extendedTrackingOn() {
    ofxQCAR & QCAR = *ofxQCAR::getInstance();
    QCAR.startExtendedTracking();
    extendedTracking = true;
    
    XML.setValue("SETUP:TRACKING", 1);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::extendedTrackingOff() {
    ofxQCAR & QCAR = *ofxQCAR::getInstance();
    QCAR.stopExtendedTracking();
    extendedTracking = false;
    
    XML.setValue("SETUP:TRACKING", 0);
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    cout << "editor.xml saved to app documents folder";
}

void realityEditor::createMemory() {
    if (nameTemp.size() > 0) {
        ofLog() << "createMemory " << nameTemp[0];
        tempMemory = make_shared<QCARState>(getCameraImage(), matrixTemp, nameTemp);
        sendThumbnail(tempMemory);
    }
}

void realityEditor::clearMemory() {
    tempMemory = nullptr;
}

void realityEditor::loadNewUI(string reloadURL) {
    ofLog() << "this is the new URL:" << reloadURL <<":";
    
    if(reloadURL !=""){
        haveChangedUIwithURL = 500;
        changedURLOk = false;
        
        interface.deactivateView();
        // interface.loadLocalFile("setup","page");
        
        cout << "this has been loaded from the webuI";
        cout << reloadURL.c_str();
        
        
        if (reloadURL.rfind("http://", 0) != 0 && reloadURL !="http")
        {
            reloadURL = "http://"+reloadURL;
        }
        
        interface.loadURL(reloadURL.c_str());
        NSLog(@"%s", reloadURL.c_str());
        
        XML.setValue("SETUP:EXTERNAL", reloadURL);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
        
        externalState = reloadURL;
        
        interface.activateView();
    }
}

void realityEditor::setDiscovery(string discoveryURL) {
    ofLog() << "this is the new URL:" << discoveryURL <<":";
    
    if(discoveryURL !=""){
        
        tcpDiscovery = false;
        
        cout << "this has been loaded from the webuI --------------------------''''''''######################## ::  ";
        cout << discoveryURL.c_str();
        cout << "    ::: this has been loaded from the webuI --------------------------''''''''########################  ";
        
        
        
        if (discoveryURL.rfind("http://", 0) != 0 && discoveryURL != "http")
        {
            discoveryURL = "http://"+discoveryURL;
            tcpDiscovery = true;
        } else if (discoveryURL.rfind("http://", 0) == 0 || discoveryURL.rfind("https://", 0) == 0){
            tcpDiscovery = true;
        }
        
        
        
        if(tcpDiscovery == true){
            
            
            cout << "######################## ::  ";
            cout << discoveryURL.c_str();
            cout << "    :::########################  ";
            
            
            
            XML.setValue("SETUP:DISCOVERY", discoveryURL);
            XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
            cout << "editor.xml saved to app documents folder";
            
            discoveryState =discoveryURL;
            
            cout << "OBJECTDISCOVERY";
            
            // HERE IS WHERE DISOVERY SHOULD BE INITIALIZED
            // OBJECTDISCOVERY
            
            ofLoadURLAsync(discoveryState + "/allObjects", "allObjects");
            
        }
    }
}

void realityEditor::removeDiscovery() {
    tcpDiscovery = false;
    XML.setValue("SETUP:DISCOVERY", "");
    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
    discoveryState ="";
    
    cout << "removed discovery";
}

void realityEditor::memorize() {
    if (!tempMemory) {
        return;
    }
    uploadMemory(tempMemory);
}

void realityEditor::remember(string dataStr) {
    ofLog() << "Is a remember";
    
    if (dataStr != "") {
        ofLog() << "With data " << dataStr;
        ofxJSONElement memoryInfo;
        QCARState* memory = new QCARState();
        memoryInfo.parse(dataStr);
        memory->name.push_back(memoryInfo["id"].asString());
        ofMatrix4x4 matrix;
        for (int i = 0; i < 16; i++) {
            matrix._mat[i / 4][i % 4] = memoryInfo["matrix"][i].asFloat();
        }
        memory->matrix.push_back(matrix);
        memory->image.allocate(1, 1, OF_IMAGE_GRAYSCALE);
        currentMemory = shared_ptr<QCARState>(memory);
    } else {
        currentMemory = tempMemory;
    }
}

void realityEditor::authenticateTouch() {
    cout << "authenticateTouch";
    interface.promptForTouch();
}

void realityEditor::clearCache() {
    interface.clearCache();
}

#pragma mark - END OF Functions Called From JavaScript
#pragma mark -

//--------------------------------------------------------------
// reponder for the asychronus file loader.
void realityEditor::urlResponse(ofHttpResponse &response) {
    // if the file is ok and the request message name equals the file downloader process name,
    // in this case "done" the folloing code is run.
    if (response.status == 200 && response.request.name == "done") {

        string loadrunner = "";

        // go trough an array of arrays of strings.
        // the array saves an object by:
        // the json hear beat | dat file laoded | xml file loaded | writen to dictionary.
        // w means loading or writing, f means nothing jet happend, t means fully loaded, n means there is an error or nothing to load.
        for (int i = 0; i < nameCount.size(); i++) {
            for (int w = 4; w < nameCount[i].size(); w++) {
                loadrunner = nameCount[i][w];

                if (loadrunner == "w") {
                    string tmpDir([NSTemporaryDirectory() UTF8String]);

                    for(int e = 0;e <  3; e++){
                        if (w == e+4) {
                            if (ofBufferToFile(tmpDir + nameCount[i][0] + "."+ arrayList[e], response.data)) {
                                nameCount[i][w] = "t";
                                NSLog(@">>copy %s",arrayList[e].c_str());
                                cons();
                            }
                            goto stop2;
                        }
                    }
                }
            }

        stop2:;

            if (nameCount[i][4] == "t" && nameCount[i][5] == "t" && nameCount[i][6] == "t" && nameCount[i][7] == "f") {
                nameCount[i][7] = "a";
                NSLog(@">>status at this point");
                cons();

            }

        }
    } else if (response.status == 200 && response.request.name == "allObjects"){

       // cout << response.data;

        allObjectJSON.parse(response.data);
        if(!allObjectJSON.isArray()){ return;}

        for (Json::ArrayIndex i = 0; i < allObjectJSON.size(); ++i)
        {
            if(allObjectJSON.isArray()){

                if(allObjectJSON[i]["id"] == "allTargetsPlaceholder000000000000"){

                        cout << "--+-+-+-+-+-#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.#.##";

                    allTargetsExist = true;
                }
            }
        }


        for (Json::ArrayIndex i = 0; i < allObjectJSON.size(); ++i)
        {
            if(allObjectJSON.isArray()){
                 processSingleHeartBeat(allObjectJSON[i].toStyledString(), allObjectJSON[i]["ip"].toStyledString());
            } else {
                    cout << "no heardbeat found";
            }
        }



        //OBJECTRESPONSE

        //processSingleHeartBeat(udpMessage)

    }
    else if (response.status > 200 && response.status <= 600){

        // in case the file does not work out, this is the message to call.
        string loadrunner = "";
        for (int i = 0; i < nameCount.size(); i++) {
            for (int w = 0; w < nameCount[i].size(); w++) {
                loadrunner = nameCount[i][w];

                if (loadrunner == "w") {
                    nameCount[i][4] = "n";
                    nameCount[i][5] = "n";
                    nameCount[i][6] = "n";
                    nameCount[i][7] = "n";
                }
            }
        }
       // cout << response.status << " " << response.error << endl;
        cons();

         }


}


//--------------------------------------------------------------
void realityEditor::update() {
    if (interfaceCounter> 30) {
        // accel = ofxAccelerometer.getForce();
        // orientation = ofxAccelerometer.getOrientation();


        if (onlyOnce) {
            NSLog(@">>once");
            // onece after the interface has been loaded, start the udp bindings.
            udpConnection.Create();
            udpConnection.Bind(52316);
            udpConnection.SetNonBlocking(true);
            udpConnection.SetEnableBroadcast(true);
            ofRegisterURLNotification(this);

            // send a request action message to all objects so that they right in time respond with a heartbeat. 3 times in a row so that it makes sure all objects are received.
            // the system parses json strings that have an action object as actions to act on.
            // {"action":"ping"} indicates that all object need to send a responding beat.
            udpConnection2.Create();
            udpConnection2.SetEnableBroadcast(true);
            udpConnection2.Connect("255.255.255.255", 52316);
            string message1 = "{\"action\":\"ping\"}";
            udpConnection2.Send(message1.c_str(), int(message1.length()));
            ofSleepMillis(50);
            udpConnection2.Send(message1.c_str(), int(message1.length()));
            ofSleepMillis(50);
            udpConnection2.Send(message1.c_str(), int(message1.length()));
            udpConnection2.Close();

            onlyOnce = false;

            if(tcpDiscovery){

                cout << "OBJECTDISCOVERY";

                // HERE IS WHERE DISCOVERY NEEDS TO HAPPEN
                // OBJECTDISCOVERY

              ofLoadURLAsync(discoveryState + "/allObjects", "allObjects");

            }

        }


        ofxQCAR &QCAR = *ofxQCAR::getInstance();

        //
        QCAR.update();
        //QCAR->mutex.lock();

        if (!currentMemory) {
            matrixTemp.clear();
            nameTemp.clear();
            //QCAR->mutex.lock();
            // tempMarker = QCAR->markersFound;

            for (int i = 0; i < QCAR.numOfMarkersFound(); i++) {
                matrixTemp.push_back(QCAR.getMarker(i).modelViewMatrix);
                nameTemp.push_back(QCAR.getMarker(i).markerName);
            }
        } else {
            matrixTemp = currentMemory->matrix;
            nameTemp = currentMemory->name;
        }

        //QCAR->mutex.unlock();


        if (waitUntil) {
            if (QCAR.numOfMarkersFound() > 0 && !currentMemory) {

                if (matrixOld == matrixTemp[0]._mat[0][0]) {
                    updateSwitch = false;
                } else {
                    updateSwitch = true;
                }
                matrixOld = matrixTemp[0]._mat[0][0];
            } else {

                if(updateSwitch) updateSwitch = false;
                else updateSwitch = true;

            }

            if (updateSwitch)
                renderJavascript();
            /*  else
             interface.runJavaScriptFromString([NSMutableString stringWithFormat:@"updateReDraw()"]);*/


            //     if(!updateSwitch)


            // update QCAR

            // download targets from the objects asynchronus.
            // we need to make sure that all processes work together using a central array of status signals.

            // check if udp message
            while (udpConnection.Receive(udpMessage, 256) > 0) {
                string address;
                int port;
                udpConnection.GetRemoteAddr(address, port);
                cout <<address << " " <<port << "\n";
             
                
                // this makes sure that only one mode is active
                if(discoveryState != "") continue;

                if(!json.parse(udpMessage)  || json["id"].asString() == "allTargetsPlaceholder000000000000"){
                    continue;
                } else if(!processSingleHeartBeat(udpMessage,address))
                {
                    
            
                    break;};
            }

              // cout <<json<< "\n";
            
            downloadTargets();

        }

        waitGUI = true;
        if (nameCount.size() == 0) waitGUI = false;

        for (int i = 0; i < nameCount.size(); i++) {
            if (nameCount[i][4] != "t" && nameCount[i][4] != "n") {
                waitGUI = false;
                // NSLog(@">>response");
            }
        }
    } else {interfaceCounter++;}
}

//--------------------------------------------------------------
void realityEditor::draw() {





    ofxQCAR & QCAR = *ofxQCAR::getInstance();
    // cout << QCAR.QCARInitTrackers() << "\t"

    if (waitUntil) {
        // run the messages that process the javascrip view.

        // render the interface

        if (!currentMemory) {
            QCAR.drawBackground();
        } else {
            currentMemory->image.draw(0, 0, ofGetWidth(), ofGetHeight());
        }



        //ofLog() << frozeCameraImage << " ++ " << freeze;
    }

    if (!waitGUI) {
        if (waitUntil) {
            imgObject.draw(20, 20);
        } else {
            imgInterface.draw(20, 20);
        }
    }


    if(haveChangedUIwithURL > 0){

        if(haveChangedUIwithURL == 1){
            if(changedURLOk == false){


                XML.setValue("SETUP:EXTERNAL", "");
                XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
                cout << "could not find UI at URL possition";

                interface.deactivateView();
//                interface.loadLocalFile("index");
                interface.loadInterfaceFromLocalServer();
                interface.activateView();

            }
        }
        haveChangedUIwithURL--;

        if(changedURLOk == false){
            string buf = "waiting for interface verification " + ofToString( haveChangedUIwithURL/60);
            ofDrawBitmapString( buf, 10, 20 );
        }

    }


}

bool realityEditor::processSingleHeartBeat(string message, string address) {
    
    //NSLog(@">>downloads");
    nameExists = false;

    // ofLog() << "Received udp message " << message;

    // if message is a valid heartbeat do the following
    if (!json.parse(message.c_str()) || json["id"].empty() || address == "") {
        
        //this calls an action
        if (!json["action"].empty()) {
            NSString *jsString4 = [NSString stringWithFormat:@"%s.onAction('%s')",
                                                             networkNamespace.c_str(),
                                                             json["action"].toStyledString().c_str()];
            // JSON with these newline characters results in unexpected EOF error when trying to send to the javascript
            NSString *jsStringWithoutNewlines = [[jsString4 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
            interface.runJavaScriptFromString(jsStringWithoutNewlines);
            NSLog(@"%@", jsStringWithoutNewlines);
            return false;

        } else {

            nameExists = true;
            NSLog(@">>udp message is not a object ping");
            NSLog(@"%s", json["id"].toStyledString().c_str());
            return false;
        }
    }
    
    // Support for zone.
    // If an object is not part of the same zone, it will not be recognized by the editor.
    if(!json["zone"].empty()){
        if(zoneText != "" && zoneState == 1){
            if(json["zone"].asString() != zoneText) {
                return false;
            }
        }
    }
    

    if(address.size()<7){
        NSLog(@">>ip was wrong");
        nameExists = true;

        return false;
    }

    string nameJson = "";
    // NSLog(@">>got something");

    // if the id is valid then check if the name is already in the array.
    // todo check for checksum!


    if(!json["tcs"].asString().empty()){

        for (int i = 0; i < nameCount.size(); i++) {

            if(nameCount[i][3].c_str() == json["tcs"].asString()){
                nameExists = true;
                return false;
            }

        }
    } else {
        for (int i = 0; i < nameCount.size(); i++) {
            if (nameCount[i][0] == json["id"].asString()) {
                nameExists = true;
                return false;
            };
        };

    }
    targetExists = false;
    string crcBuffer = "";
    if (nameExists == false) {

        int numDragTags = XMLTargets.getNumTags("target");

        if(numDragTags > 0){

            for(int i = 0; i< numDragTags; i++){

                string id_ = XMLTargets.getValue("target:id", "", i);
                string ip_ = XMLTargets.getValue("target:ip", "", i);
                string vn_ = XMLTargets.getValue("target:vn", "0", i);
                string tcs_ = XMLTargets.getValue("target:tcs", "0", i);

                if(id_ == json["id"].asString() &&
                        tcs_  == json["tcs"].asString() &&
                        tcs_  != "0"){

                    crc32reset();

                    // this is reproducing the checksom from the actual files.
                    // if the files are corrupt and not matching with the server version then it forces a new download.

                   // if(!allTargetsExist || json["id"].asString() == "allTargetsPlaceholder000000000000") {
                    string tmpDir([NSTemporaryDirectory() UTF8String]);

                    buff = ofBufferFromFile(tmpDir + id_ + ".jpg");
                    crc32(buff.getData(),buff.size());
                    buff = ofBufferFromFile(tmpDir + id_ + ".xml");
                    crc32(buff.getData(),buff.size());
                    buff = ofBufferFromFile(tmpDir + id_ + ".dat");
                    crcBuffer =  itob62(crc32(buff.getData(),buff.size()));

              //  }
                   
                    
                    if(crcBuffer == tcs_ && (!allTargetsExist || json["id"].asString() != "allTargetsPlaceholder000000000000")){
                            cout <<"allsoooneee-------";
                        
                        targetExists = true;


                                    if(id_ != "allTargetsPlaceholder000000000000"){
                        NSString *jsString3 = [NSString stringWithFormat:@"%s.addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})",
                                                                         networkNamespace.c_str(),
                                                                         id_.c_str(),
                                                                         ip_.c_str(),
                                                                         stoi(vn_.c_str()),
                                                                         tcs_.c_str()];
                        interface.runJavaScriptFromString(jsString3);
                                    }
                        targetExists = true;
                        NSLog(@">>found double for %s",json["id"].asString().c_str());
                        break;

                    } else {
                        targetExists = false;
                    }

                }

            }
        }
    }

    // if name is not in the array generate a new row of an array of strings. and fill them with "f" so that the software knows to process all.
    // remember, the first cell is the full json heart beat, the second indicates the status of the dat file the 3th the status of the xml file and the last cell indicates the status of adding the files to the dictionary.
    if (nameExists == false) {


        bool yespush = true;

        for (int i = 0; i < nameCount.size(); i++) {
            if (nameCount[i][0] == json["id"].asString()) {


                if(!allTargetsExist || nameCount[i][0] == "allTargetsPlaceholder000000000000") {

                    ofxQCAR &QCAR = *ofxQCAR::getInstance();
                    if (datasetList.size() > 0)
                        QCAR.removeExtraTarget(datasetList[i]);
                }

                datasetHolder = i;

                nameCount[i][0] = json["id"].asString();
                nameCount[i][1] = address;
                nameCount[i][2] = json["vn"].asString();
                nameCount[i][3] = json["tcs"].asString();
                nameCount[i][4] = "f";
                nameCount[i][5] = "f";
                nameCount[i][6] = "f";
                nameCount[i][7] = "f";

                 if(allTargetsExist || nameCount[i][0] != "allTargetsPlaceholder000000000000"){
                     nameCount[i][4] = "t";
                     nameCount[i][5] = "t";
                     nameCount[i][6] = "t";
                     nameCount[i][7] = "a";
                 }



                string tmpDir([NSTemporaryDirectory() UTF8String]);


                files_.removeFile(tmpDir + nameCount[i][0] + ".jpg");
                files_.removeFile(tmpDir + nameCount[i][0] + ".xml");
                files_.removeFile(tmpDir + nameCount[i][0] + ".dat");



                yespush = false;

            };
        };


        if(yespush){
            vector<string> row;
            row.push_back(json["id"].asString()); //0
            row.push_back(address); // 1
            if(!json["vn"].empty()){                //2
                row.push_back(json["vn"].asString());
            } else{
                row.push_back("0");
            }
            if(!json["tcs"].empty()){               //3
                row.push_back(json["tcs"].asString());
            } else{
                row.push_back("0");
            }
            if(targetExists) {
                row.push_back("t");  //4
                row.push_back("t"); //5
                row.push_back("t"); //6
                row.push_back("a"); //7
         /*  } else if (allTargetsExist || json["id"].asString() == "allTargetsPlaceholder000000000000"){
                row.push_back("t");  //4
                row.push_back("t"); //5
                row.push_back("t"); //6
                row.push_back("a"); //7*/
            } else
            {
                row.push_back("f");  //4
                row.push_back("f"); //5
                row.push_back("f"); //6
                row.push_back("f"); //7
            }

            nameCount.push_back(row);
            NSLog(@">>adding new object");
            cons();
        }
    }

    return true;
}





void realityEditor::downloadTargets() {
    string loadrunner = "";
    // file handling

    // process the file downloads
    loadrunner = "";
    
    for (int i = 0; i < nameCount.size(); i++) {
        if (loadrunner == "w") {
            break;
        }
        
        for (int w = 4; w < nameCount[i].size(); w++) {
            loadrunner = nameCount[i][w];
            if (loadrunner == "w") {
                break;
            }
            else if (loadrunner == "f") {
                
                for(int e = 0;e <  3; e++){
                    
                    if (w == e+4) {
                        string objName = getName(nameCount[i][0]);
                        string sURL = "http://" + nameCount[i][1] + ":8080/obj/" + objName + "/target/target."+arrayList[e];
                        ofLoadURLAsync(sURL, "done");
                        nameCount[i][w] = "w";
                        loadrunner = "w";
                        NSLog(@">>downloading %s",arrayList[e].c_str());
                        cons();
                        loadrunner = "w";
                        goto stop1;
                    }
                    
                }
                
            }
            // process the dictonary addon
            else if (loadrunner == "a") {
                string tmpDir([NSTemporaryDirectory() UTF8String]);
                ofxQCAR & QCAR = *ofxQCAR::getInstance();
                
                cout <<"--------------------";
                cout <<nameCount[i][0];
                cout <<"--------------------";
                
                if(nameCount[i][w] == "a"){
                    
                       if(!allTargetsExist || nameCount[i][0] == "allTargetsPlaceholder000000000000"){

                    if(datasetHolder ==100000){
                        datasetList.push_back(QCAR.addExtraTarget(tmpDir + nameCount[i][0] + ".xml"));
                        
                    } else {
                        if(datasetList.size()>0){
                        datasetList[datasetHolder]=(QCAR.addExtraTarget(tmpDir + nameCount[i][0] + ".xml"));
                        datasetHolder =100000;
                        }
                    }
                       }
                    
                    
                    cout << "this set size: "<< datasetList.size() << endl;
                    
                      if(nameCount[i][0] != "allTargetsPlaceholder000000000000"){

                    NSString *jsString3 = [NSString stringWithFormat:@"%s.addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})",
                                           networkNamespace.c_str(),
                                           nameCount[i][0].c_str(),
                                           nameCount[i][1].c_str(),
                                           stoi(nameCount[i][2].c_str()),
                                           nameCount[i][3].c_str()];
                    interface.runJavaScriptFromString(jsString3);
                    
                      }
                    
                    
                    int numDragTags2 = XMLTargets.getNumTags("target");
                    
                    bool checkDouble = false;
                    if(numDragTags2 > 0){
                        
                        for(int e = 0; e< numDragTags2; e++){
                            if(nameCount[i][0] == XMLTargets.getValue("target:id", "", e)){
                                XMLTargets.setValue("target:id", nameCount[i][0], e);
                                XMLTargets.setValue("target:ip", nameCount[i][1], e);
                                XMLTargets.setValue("target:vn", nameCount[i][2], e);
                                XMLTargets.setValue("target:tcs",nameCount[i][3], e);
                                checkDouble = true;
                            };
                        }
                    }
                    
                    if(!checkDouble) {
                        int tagNum = XMLTargets.addTag("target");
                        XMLTargets.setValue("target:id", nameCount[i][0], tagNum);
                        XMLTargets.setValue("target:ip", nameCount[i][1], tagNum);
                        XMLTargets.setValue("target:vn", nameCount[i][2], tagNum);
                        XMLTargets.setValue("target:tcs", nameCount[i][3], tagNum);
                    }
                    XMLTargets.saveFile(ofxiOSGetDocumentsDirectory() + "targets.xml" );
                    
                    
                }
                nameCount[i][w] = "t";
                
                
                loadrunner = "w";
                NSLog(@">>adding target");
                
                if(extendedTracking){
                    ofxQCAR & QCAR = *ofxQCAR::getInstance();
                    QCAR.startExtendedTracking();
                }
                cons();
                loadrunner = "w";
                
                goto stop1;
            }
        }
    stop1:;
    }
    stop2:;
}

void realityEditor::qcarInitARDone(NSError *error) {
    qCARInitARDone = true;
    sendProjectionMatrix();
}

NSString* realityEditor::stringFromMatrix(ofMatrix4x4 mat) {
    return [NSString stringWithFormat:@"[%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf]",
            mat._mat[0][0],
            mat._mat[0][1],
            mat._mat[0][2],
            mat._mat[0][3],
            mat._mat[1][0],
            mat._mat[1][1],
            mat._mat[1][2],
            mat._mat[1][3],
            mat._mat[2][0],
            mat._mat[2][1],
            mat._mat[2][2],
            mat._mat[2][3],
            mat._mat[3][0],
            mat._mat[3][1],
            mat._mat[3][2],
            mat._mat[3][3]
            ];
}

void realityEditor::sendProjectionMatrix() {
    float nearPlane = 2;
    float farPlane = 2000;
    const Vuforia::CameraCalibration& cameraCalibration = Vuforia::CameraDevice::getInstance().getCameraCalibration();
    Vuforia::Matrix44F projectionMatrix = Vuforia::Tool::getProjectionGL(cameraCalibration, nearPlane, farPlane);

    ofMatrix4x4 projMatrix = ofMatrix4x4(projectionMatrix.data);
    NSString* code = [NSString stringWithFormat:@"%s.setProjectionMatrix(%@);", arNamespace.c_str(), stringFromMatrix(projMatrix)];
    ofLog() << [code UTF8String];
    interface.runJavaScriptFromString(code);
}

// generate the javascript messages
void realityEditor::renderJavascript() {
    if (nameTemp.size() > 0) {
       
        stringforTransform = [NSMutableString stringWithFormat:@"%s.update({", drawNamespace.c_str()];

        // now for all objects we add json elements indicating the name of the marker as the object name and following the model view matrix.
        //
        for (int i = 0; i < nameTemp.size(); i++) {

            tempMatrix = matrixTemp[i];

            [stringforTransform appendFormat:@"'%s':%@",
             nameTemp[i].c_str(),
             stringFromMatrix(tempMatrix)
             ];
            // formating condition for json.
            if (i < matrixTemp.size() - 1) {
                [stringforTransform appendString:@","];
            }


        }
        //
        // end of string generation.
        //   [stringforTransform appendString:@"}"];

        /*  if(shouldSendAccelerationData == true){
         [stringforTransform appendFormat:@",'acl':[%lf,%lf,%lf,%lf,%lf]",
         accel.x,
         accel.y,
         accel.z,
         orientation.x,
         orientation.y
         ];
         }
         */

        [stringforTransform appendString:@"})"];


    } else {
        stringforTransform = [NSMutableString stringWithFormat:@"%s.update({})", drawNamespace.c_str()];
        
        /* if(shouldSendAccelerationData == true){
         [stringforTransform appendFormat:@",'acl':[%lf,%lf,%lf,%lf,%lf]",
         accel.x,
         accel.y,
         accel.z,
         orientation.x,
         orientation.y
         ];
         }*/
        //  [stringforTransform appendString:@"})"];

    }
    // finally we call the dunction to update the html view.
    interface.runJavaScriptFromString(stringforTransform);


}

// utilities for rendering the conditions of the download process.
void realityEditor::cons() {
    NSLog(@">>cons");
   /* for (int i = 0; i < nameCount.size(); i++) {
        NSLog(@"%s %s %s %s, name: %s version: %s  check: %s", nameCount[i][4].c_str(), nameCount[i][5].c_str(), nameCount[i][6].c_str(), nameCount[i][7].c_str(), nameCount[i][0].c_str(),nameCount[i][2].c_str(),nameCount[i][3].c_str());
    }*/
    
    int i = 0;
    
    if(nameCount.size()>0){
   i= nameCount.size()-1;

       NSLog(@"%s %s %s %s, name: %s version: %s  check: %s", nameCount[i][4].c_str(), nameCount[i][5].c_str(), nameCount[i][6].c_str(), nameCount[i][7].c_str(), nameCount[i][0].c_str(),nameCount[i][2].c_str(),nameCount[i][3].c_str());
      }
}

void realityEditor::deviceOrientationChanged(int newOrientation){
    // ofxQCAR & QCAR = *ofxQCAR::getInstance();
    
    
    if(newOrientation == 4){
        //  ofSetOrientation((ofOrientation)newOrientation);
        //   QCAR.setOrientation(OFX_QCAR_ORIENTATION_LANDSCAPE_RIGHT);
        
    }
    
    if(newOrientation == 3){
        // ofSetOrientation((ofOrientation)newOrientation);
        
        //  QCAR.setOrientation(OFX_QCAR_ORIENTATION_LANDSCAPE_LEFT);
    }
}

ofImage realityEditor::getCameraImage() {
    int width  = ofGetWidth();
    int height = ofGetHeight();
    int bufHeight = height / 2;
    int bufWidth = width / 2;

    NSInteger myDataLength = width * height * 4;
    GLubyte *buffer = (GLubyte *) malloc(sizeof(GLubyte) * myDataLength);

    GLubyte *bufferFlipped = (GLubyte *) malloc(sizeof(GLubyte) * bufWidth * bufHeight * 3);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

    // Skip every other pixel in buffer, writing RGB only
    for(int y = 0; y < height; y += 2) {
        int bufY = y / 2;
        for(int x = 0; x < width; x += 2) {
            int bufX = x / 2;
//            int r = buffer[y * 4 * width + x * 4 + 0];
//            int g = buffer[y * 4 * width + x * 4 + 1];
//            int b = buffer[y * 4 * width + x * 4 + 2];
//            int intensity = 0.2989 * r + 0.5870 * g + 0.1140 * b;
//            bufferFlipped[(height / 2 - 1 - y / 2) * width / 2 + x / 2] = intensity;
            for (int i = 0; i < 3; i++) {
                bufferFlipped[((bufHeight - 1 - bufY) * bufWidth + bufX) * 3 + i] = buffer[y * 4 * width + x * 4 + i];
            }
        }
    }
    free(buffer);	// free original buffer

    ofImage cameraImage;
    cameraImage.setFromPixels(bufferFlipped, width / 2, height / 2, OF_IMAGE_COLOR);
    free(bufferFlipped);
    return cameraImage;
}

void realityEditor::sendThumbnail(shared_ptr<QCARState> memory) {
    ofImage thumbnail;
    thumbnail.clone(memory->image);
    thumbnail.resize(thumbnailWidth, thumbnailHeight);

    NSString* base64 = convertImageToBase64(thumbnail);

    NSString* jsStr = [NSString stringWithFormat:@"%s.receiveThumbnail(\"data:image/jpeg;base64,%@\")", memoryNamespace.c_str(), base64];
    interface.runJavaScriptFromString(jsStr);
}

string realityEditor::getName(string objectId) {
    if (objectId.length() < 12) {
        ofLog() << "Warning: object id too short";
        return objectId;
    }
    return objectId.substr(0,objectId.length() - 12);
}

void realityEditor::uploadMemory(shared_ptr<QCARState> memory) {
    ofLog() << "memory 1: " << memory.get();
    if (memory->name.size() > 1 || memory->name.size() == 0) {
        ofLog() << "Bailing because we want exactly one marker";
        return;
    }
    ofLog() << "memory 2: " << memory.get();

    string objName = getName(memory->name[0]);

    string ip;
    string id;
    bool found = false;
    for (vector<string> info : nameCount) {
        string infoName = getName(info[0]); // object id
        if (objName == infoName) {
            id = info[0];
            ip = info[1];
            found = true;
            break;
        }
    }

    if (!found) {
        ofLog() << "No object found in nameCount";
        return;
    }

    if (memoryUploader && !memoryUploader->done) {
        ofLog() << "Already processing one upload";
        return;
    }
    memoryUploader = make_shared<MemoryUploader>(id, ip, memory);
    memoryThreadPool.start(*memoryUploader);
}

NSString* realityEditor::convertImageToBase64(ofImage image) {
    ofBuffer buffer;
    ofSaveImage(image.getPixels(), buffer, OF_IMAGE_FORMAT_JPEG, OF_IMAGE_QUALITY_BEST);
    ostringstream ss;
    Poco::Base64Encoder encoder(ss);
    // Poco's underlying Base64EncoderBuf automatically inserts \r\n every 72 characters
    encoder << buffer;
    encoder.close();
    NSString* rawBase64 = [NSString stringWithUTF8String:ss.str().c_str()];
    return [rawBase64 stringByReplacingOccurrencesOfString: @"\r\n" withString: @""];
}

/**
 * @param req - Full host of request, including data to be placed in {data}
 * @param requestName - Desired name of request. If found, request is of form `requestName + data`
 * @param data - String to store data in
 * @return Whether the request has name (prefix) requestName
 */
bool realityEditor::getDataFromReq(string req, string requestName, string* data) {
    size_t foundIdx = req.find(requestName);
    if (foundIdx != 0) {
        return false;
    }

    *data = req.substr(requestName.size(), req.size());
    return true;
}


//--------------------------------------------------------------
void realityEditor::exit() {
    ofxQCAR & QCAR = *ofxQCAR::getInstance();
    QCAR.exit();
}







///---------- UTILITIES --------------------------------


/*-
 *  COPYRIGHT (C) 1986 Gary S. Brown.  You may use this program, or
 *  code or tables extracted from it, as desired without restriction.
 *
 *  First, the polynomial itself and its table of feedback terms.  The
 *  polynomial is
 *  X^32+X^26+X^23+X^22+X^16+X^12+X^11+X^10+X^8+X^7+X^5+X^4+X^2+X^1+X^0
 *
 *  Note that we take it "backwards" and put the highest-order term in
 *  the lowest-order bit.  The X^32 term is "implied"; the LSB is the
 *  X^31 term, etc.  The X^0 term (usually shown as "+1") results in
 *  the MSB being 1
 *
 *  Note that the usual hardware shift register implementation, which
 *  is what we're using (we're merely optimizing it by doing eight-bit
 *  chunks at a time) shifts bits into the lowest-order term.  In our
 *  implementation, that means shifting towards the right.  Why do we
 *  do it this way?  Because the calculated CRC must be transmitted in
 *  order from highest-order term to lowest-order term.  UARTs transmit
 *  characters in order from LSB to MSB.  By storing the CRC this way
 *  we hand it to the UART in the order low-byte to high-byte; the UART
 *  sends each low-bit to hight-bit; and the result is transmission bit
 *  by bit from highest- to lowest-order term without requiring any bit
 *  shuffling on our part.  Reception works similarly
 *
 *  The feedback terms table consists of 256, 32-bit entries.  Notes
 *
 *      The table can be generated at runtime if desired; code to do so
 *      is shown later.  It might not be obvious, but the feedback
 *      terms simply represent the results of eight shift/xor opera
 *      tions for all combinations of data and CRC register values
 *
 *      The values must be right-shifted by eight bits by the "updcrc
 *      logic; the shift must be unsigned (bring in zeroes).  On some
 *      hardware you could probably optimize the shift in assembler by
 *      using byte-swap instructions
 *      polynomial $edb88320
 *
 *
 * CRC32 code derived from work by Gary S. Brown.
 */



static uint32_t crc32Lookup[] = {
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
    0xe963a535, 0x9e6495a3,	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
    0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
    0xf3b97148, 0x84be41de,	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,	0x14015c4f, 0x63066cd9,
    0xfa0f3d63, 0x8d080df5,	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
    0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,	0x35b5a8fa, 0x42b2986c,
    0xdbbbc9d6, 0xacbcf940,	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
    0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,	0x76dc4190, 0x01db7106,
    0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
    0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
    0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
    0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
    0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
    0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
    0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
    0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
    0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
    0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
    0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
    0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
    0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
    0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
    0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
    0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
    0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
    0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
    0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
    0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
    0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
    0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
    0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

int32_t realityEditor::crc32(const void* data, size_t length)
{
    unsigned char* current = (unsigned char*) data;
    while (length--)
        crc = (crc >> 8) ^ crc32Lookup[(crc & 0xFF) ^ *current++];
    return ~crc;
}

string realityEditor::itob62( long i )
{
    unsigned long u = *reinterpret_cast<unsigned long*>( &i ) ;
    std::string b32 ;
    
    do
    {
        long d = u % 62 ;
        if( d < 10 )
        {
            b32.insert( 0, 1, '0' + d ) ;
        }
        else if (d < 36)
        {
            b32.insert( 0, 1, 'a' + d - 10 ) ;
        }
        else
        {
            b32.insert( 0, 1, 'A' + d - 36 ) ;
        }
        
        u /= 62 ;
        
    } while( u > 0 );
    
    return b32 ;
}


void realityEditor::crc32reset(){
    crc = 0xffffffff;
}






