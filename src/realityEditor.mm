#include "realityEditor.h"


static const string kLicenseKey = "***REMOVED***";

//--------------------------------------------------------------
void realityEditor::setup() {

    numbersToMuch = 50;
    
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
    externalState = XML.getValue("SETUP:EXTERNAL", "");

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

    // initialize vuforia
    ofxVuforia & Vuforia = *ofxVuforia::getInstance();
    Vuforia.setLicenseKey(kLicenseKey); // ADD YOUR APPLICATION LICENSE KEY HERE.
    Vuforia.addMarkerDataPath("target.xml");
    Vuforia.autoFocusOn();
    Vuforia.setOrientation(OFX_Vuforia_ORIENTATION_LANDSCAPE_LEFT);
    Vuforia.setCameraPixelsFlag(true);
    Vuforia.setMaxNumOfMarkers(5);
    Vuforia.setup();    
    
    
  
        
    if(extTrackingState){
        
            ofxVuforia & Vuforia = *ofxVuforia::getInstance();
            Vuforia.startExtendedTracking();
            extendedTracking = true;
    }else{
        ofxVuforia & Vuforia = *ofxVuforia::getInstance();
        Vuforia.stopExtendedTracking();
        extendedTracking = false;

    }
    
    //usleep(5000000);
    
        interface.initializeWithCustomDelegate(this);
    
    if(externalState !=""){
        
        cout << "loading interface from: " << externalState;
      
        interface.loadURL(externalState.c_str());
        interface.activateView();
        haveChangedUIwithURL = 500;
    }else{


    /**********************************************
    INITIALIZING THE INTERFACE
    **********************************************/

    interface.loadLocalFile("index");
  //   interface.loadURL("http://html5test.com");
   
    interface.activateView();
        
    }
    
    ofLog()<<"**+++***++***+: "<< ofGetWindowSize() ;
    
      ofLog()<<"**+++***++***+: "<< ofGetWindowHeight() ;
     ofLog()<<"**+++***++***+: "<< ofGetWindowWidth() ;
    
   
 
    if(thisWindow.isRetinaEnabled()){
        screenScale =2;
    }
    
       cameraImage.allocate(ofGetWindowHeight()/screenScale, ofGetWindowHeight()/screenScale, OF_IMAGE_COLOR);
    fbo.allocate(ofGetWindowHeight()/screenScale, ofGetWindowHeight()/screenScale);
    
        fbo2.allocate(ofGetWindowHeight()/screenScale, ofGetWindowHeight()/screenScale);

   
}

/**********************************************
HANDLING REQUESTS FROM JS/HTML (JS->C++)
**********************************************/
void realityEditor::handleCustomRequest(NSString *request) {
    NSLog(@"------------------------------------------------------------%@", request);
    string reqstring([request UTF8String]); 

    
    ofLog() << reqstring;
    
    

        
    
    // if the html interface is loaded kickoff will be send to the c++ code.
    if (reqstring == "kickoff") {
        waitUntil = true;
        NSLog(@"kickoff");
        
        if(haveChangedUIwithURL > 0){
              reloader = true;
            changedURLOk = true;
            // here is where we need to write the permanent link saving mechanism
        }
        
        projectionMatrixSend = false;

        // help to reestablish the arrays when reloaded the interface
        // needs some more work on getting back and forth all the different objects


        // if the message is reload then the interface reloads and all objects are resent to the editor
        
        NSString *stateSender = [NSString stringWithFormat:@"setStates(%d, %d, %d, \"%s\")", developerState, extTrackingState, clearSkyState, externalState.c_str()];
         interface.runJavaScriptFromString(stateSender);
        
        NSString *deviceSender = [NSString stringWithFormat:@"setDeviceName(\"%s\")", ofxiOSGetDeviceRevision().c_str()];
        interface.runJavaScriptFromString(deviceSender);
 
   //  NSLog(stateSender);


       // if (reloader == true) {
            

            cout<< "---->>>---<<<---Sending reload";
        
        
            for (int i = 0; i < nameCount.size(); i++) {
                    cout<<&nameCount[i];
                NSString *jsString3 = [NSString stringWithFormat:@"addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})", nameCount[i][0].c_str(), nameCount[i][1].c_str(), stoi(nameCount[i][2].c_str()) ,nameCount[i][3].c_str()];
                interface.runJavaScriptFromString(jsString3);
                //   NSLog(@"reload interfaces");
            }
        //}
        NSLog(@"reload interfaces");
    }

    if (reqstring == "reload") {
        
        
        if(externalState !=""){
            interface.deactivateView();
            interface.loadURL(externalState.c_str());
            interface.activateView();
        }else{
            interface.deactivateView();
            interface.loadLocalFile("index");
            interface.activateView();
        }
        
        
        
        
        reloader = true;
        NSString *stateSender = [NSString stringWithFormat:@"setStates(%d, %d, %d, \"%s\")", developerState, extTrackingState, clearSkyState, externalState.c_str()];
        interface.runJavaScriptFromString(stateSender);
     
    }

    if (reqstring == "freeze") {
        freeze = true;
    }
    if (reqstring == "unfreeze") {
        freeze = false;
        frozeCameraImage = false;
      ofxVuforia & Vuforia = *ofxVuforia::getInstance();
        Vuforia.resume();
    }
    if (reqstring == "sendAccelerationData") {
        sendAccelerationData = true;
    }

    if (reqstring == "developerOn") {
        XML.setValue("SETUP:DEVELOPER", 1);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";

    }
    if (reqstring == "developerOff") {
        XML.setValue("SETUP:DEVELOPER", 0);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
    }
    
    if (reqstring == "clearSkyOn") {
        XML.setValue("SETUP:CLEARSKY", 1);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
        
    }
    if (reqstring == "clearSkyOff") {
        XML.setValue("SETUP:CLEARSKY", 0);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
    }

    
    if (reqstring == "extendedTrackingOn") {
         ofxVuforia & Vuforia = *ofxVuforia::getInstance();
        Vuforia.startExtendedTracking();
        extendedTracking = true;
        
        XML.setValue("SETUP:TRACKING", 1);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
        
    }
    
    if (reqstring == "extendedTrackingOff") {
        ofxVuforia & Vuforia = *ofxVuforia::getInstance();
        Vuforia.stopExtendedTracking();
        extendedTracking = false;
        
        XML.setValue("SETUP:TRACKING", 0);
        XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
        cout << "editor.xml saved to app documents folder";
    }
    
    
    
    string str2 ("loadNewUI");
   
    size_t found1 = reqstring.find(str2);

    
    if(found1 == 0){
  
        
          long endBlock = reqstring.find_first_of("loadNewUI");
    
     ofLog() << endBlock;
    
            if(endBlock ==0){
                
                
                
              string reloadURL = reqstring.substr (endBlock+9, reqstring.size());
                
                ofLog() << "this is the new URL:" << reloadURL <<":";
            
                if(reloadURL !=""){
                      haveChangedUIwithURL = 500;
                            changedURLOk = false;
                
                interface.deactivateView();
                 // interface.loadLocalFile("setup","page");
                 
                    cout << "this has been loaded from the webuI";
                    cout << reloadURL.c_str();
                    
                 interface.loadURL(reloadURL.c_str());
                NSLog(@"%s", reloadURL.c_str());
                    
                    XML.setValue("SETUP:EXTERNAL", reloadURL);
                    XML.saveFile(ofxiOSGetDocumentsDirectory() + "editor.xml" );
                    cout << "editor.xml saved to app documents folder";
                    
                    externalState =reloadURL;
                    
                
                //    interface.loadURL("http://html5test.com");
                    
                interface.activateView();
                  
                    
            
                }
                
                
            }
    
   
    
    
    }

}

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
    } else {

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
        cout << response.status << " " << response.error << endl;
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
        }


        ofxVuforia &Vuforia = *ofxVuforia::getInstance();

        //
        Vuforia.update();
        //Vuforia->mutex.lock();

        matrixTemp.clear();
        nameTemp.clear();
        //Vuforia->mutex.lock();
        // tempMarker = Vuforia->markersFound;

        for (int i = 0; i < Vuforia.numOfMarkersFound(); i++) {
            matrixTemp.push_back(Vuforia.getMarker(i).modelViewMatrix);
            nameTemp.push_back(Vuforia.getMarker(i).markerName);
        }


        if (!frozeCameraImage && freeze == true) {

            /*    int cameraW = Vuforia.getCameraWidth();
                int cameraH = Vuforia.getCameraHeight();
                unsigned char * cameraPixels = Vuforia.getCameraPixels();
                if(cameraW > 0 && cameraH > 0 && cameraPixels != NULL) {
                    if(cameraImage.isAllocated() == false ) {
                        cameraImage.allocate(cameraW, cameraH, OF_IMAGE_GRAYSCALE);
                    }
                    cameraImage.setFromPixels(cameraPixels, cameraW, cameraH, OF_IMAGE_GRAYSCALE);
                    if(Vuforia.getOrientation() == OFX_Vuforia_ORIENTATION_PORTRAIT) {
                        cameraImage.rotate90(1);
                    } else if(Vuforia.getOrientation() == OFX_Vuforia_ORIENTATION_LANDSCAPE) {
                        cameraImage.mirror(true, true);
                    }
                }
                // todo, once OF 0.9 is final we have to add the color image again
                // cameraImage.grabScreen(0, 0, ofGetWidth(), ofGetHeight());*/
            Vuforia.pause();
            frozeCameraImage = true;
            ofLog() << "+++++++ i get it";

        }

        //Vuforia->mutex.unlock();


        if (waitUntil) {

            if (Vuforia.numOfMarkersFound() > 0 && !freeze) {

                if (matrixOld == matrixTemp[0]._mat[0][0]) {
                    updateSwitch = false;
                } else {
                    updateSwitch = true;
                }
                matrixOld = matrixTemp[0]._mat[0][0];
            } else {
                
               // updateSwitch = true;
                if(updateSwitch) updateSwitch = false;
                else updateSwitch = true;

            }
            
                if (updateSwitch)
                    renderJavascript();

            //     if(!updateSwitch)


            // update vuforia

            // download targets from the objects asynchronus.
            // we need to make sure that all processes work together using a central array of status signals.
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
    
  
    
 
    
 ofxVuforia & Vuforia = *ofxVuforia::getInstance();
       // cout << Vuforia.VuforiaInitTrackers() << "\t"

    if (waitUntil) {
// run the messages that process the javascrip view.

        // render the interface
             //  ofLog() << frozeCameraImage << " ++ " << freeze;
   
  /* if (freeze && frozeCameraImage) {
            cameraImage.draw(0, 0, ofGetWidth(), ofGetHeight());
        }else{
            Vuforia.drawBackground();
        }*/
  
      
        //interface.runJavaScriptFromString([NSMutableString stringWithFormat:@"updateReDraw()"]);
     
        Vuforia.drawBackground();
      
        
        
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
                interface.loadLocalFile("index");
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

void realityEditor::downloadTargets() {
    string loadrunner = "";
    // file handling

    // check if udp message
    while (udpConnection.Receive(udpMessage, 256) > 0) {
        //NSLog(@">>downloads");
        string message = udpMessage;
        nameExists = false;

       // cout << message;
        // if message is a valid heartbeat do the following
        if (!json.parse(message.c_str()) || json["id"].empty() || json["ip"].empty()) {
            nameExists = true;
            NSLog(@">>udp message is not a object ping");
                 NSLog(@"%s", json["id"].asString().c_str());
            goto stop2;
            break;

        }

         if(json["ip"].asString().size()<7){
             NSLog(@">>ip was wrong");
                nameExists = true;
             goto stop2;
                break;
            }

//this calls an action
        if (!json["action"].empty()) {
            NSString *jsString4 = [NSString stringWithFormat:@"action('%s')", json["action"].asString().c_str()];
            interface.runJavaScriptFromString(jsString4);
            NSLog(@"%@", jsString4);
            goto stop2;
            break;
        }

        string nameJson = "";
        // NSLog(@">>got something");

        // if the id is valid then check if the name is already in the array.
        // todo check for checksum!
        
        
        if(!json["tcs"].asString().empty()){
            
            for (int i = 0; i < nameCount.size(); i++) {
                
                if(nameCount[i][3].c_str() == json["tcs"].asString()){
                    nameExists = true;
                    goto stop2;
                    break;
                }
             
            }
        } else {
            for (int i = 0; i < nameCount.size(); i++) {
                if (nameCount[i][0] == json["id"].asString()) {
                    nameExists = true;
                    goto stop2;
                    break;
                };
            };
            
        }
        targetExists = false;
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

                   NSString *jsString3 = [NSString stringWithFormat:@"addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})",
                                   id_.c_str(),
                                   ip_.c_str(),
                                   stoi(vn_.c_str()),
                                   tcs_.c_str()];
                   interface.runJavaScriptFromString(jsString3);
                   targetExists = true;
                   NSLog(@">>found double for %s",json["id"].asString().c_str());
                   break;
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
                 
                     ofxVuforia & Vuforia = *ofxVuforia::getInstance();
                    Vuforia.removeExtraTarget(datasetList[i]);
                    
                    datasetHolder = i;
                    
                    nameCount[i][0] = json["id"].asString();
                    nameCount[i][1] = json["ip"].asString();
                    nameCount[i][2] = json["vn"].asString();
                    nameCount[i][3] = json["tcs"].asString();
                    nameCount[i][4] = "f";
                    nameCount[i][5] = "f";
                     nameCount[i][6] = "f";
                     nameCount[i][7] = "f";
                    
                    
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
            row.push_back(json["ip"].asString()); // 1
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
    }

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
                        string objName = nameCount[i][0];
                        objName.erase(objName.end() - 12, objName.end());
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
                ofxVuforia & Vuforia = *ofxVuforia::getInstance();
                
                cout <<"--------------------";
                cout <<nameCount[i][0];
                cout <<"--------------------";
                
                if(nameCount[i][w] == "a"){
                    
                    if(datasetHolder ==100000){
                           datasetList.push_back(Vuforia.addExtraTarget(tmpDir + nameCount[i][0] + ".xml"));
                        
                    } else {
                         datasetList[datasetHolder]=(Vuforia.addExtraTarget(tmpDir + nameCount[i][0] + ".xml"));
                        datasetHolder =100000;
                    }
                    
            
                    
                   cout << "this set size: "<< datasetList.size() << endl;

                    NSString *jsString3 = [NSString stringWithFormat:@"addHeartbeatObject({'id':'%s','ip':'%s','vn':%i,'tcs':'%s'})", nameCount[i][0].c_str(), nameCount[i][1].c_str(), stoi(nameCount[i][2].c_str()) ,nameCount[i][3].c_str()];
                    interface.runJavaScriptFromString(jsString3);




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
                    ofxVuforia & Vuforia = *ofxVuforia::getInstance();
                    Vuforia.startExtendedTracking();
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

// generate the javascript messages
void realityEditor::renderJavascript() {
 ofxVuforia & Vuforia = *ofxVuforia::getInstance();

    if (nameTemp.size() > 0) {

        if (projectionMatrixSend == false) {
               //Vuforia->mutex.lock();
            tempMatrix = Vuforia.getProjectionMatrix();
              // Vuforia->mutex.unlock();
            
         /*   cout << "-------start--------";
            
            cout << ":" <<  tempMatrix._mat[0][0];
            cout << ":" <<   tempMatrix._mat[0][1];
            cout << ":" <<   tempMatrix._mat[0][2];
            cout << ":" <<   tempMatrix._mat[0][3];
            cout << ":" <<   tempMatrix._mat[1][0];
            cout << ":" <<   tempMatrix._mat[1][1];
            cout << ":" <<   tempMatrix._mat[1][2];
            cout << ":" <<  tempMatrix._mat[1][3];
            cout << ":" <<  tempMatrix._mat[2][0];
            cout << ":" <<  tempMatrix._mat[2][1];
            cout << ":" <<  tempMatrix._mat[2][2];
            cout << ":" <<  tempMatrix._mat[2][3];
            cout << ":" <<  tempMatrix._mat[3][0];
            cout << ":" <<  tempMatrix._mat[3][1];
            cout << ":" <<  tempMatrix._mat[3][2];
            cout << ":" <<  tempMatrix._mat[3][3];
            
            cout << "-------xxxx--------";*/
      
            
            pMatrix = [NSString stringWithFormat:@"setProjectionMatrix([%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf])",
                                                 tempMatrix._mat[0][0],
                                                 tempMatrix._mat[0][1],
                                                 tempMatrix._mat[0][2],
                                                 tempMatrix._mat[0][3],
                                                 tempMatrix._mat[1][0],
                                                 tempMatrix._mat[1][1],
                                                 tempMatrix._mat[1][2],
                                                 tempMatrix._mat[1][3],
                                                 tempMatrix._mat[2][0],
                                                 tempMatrix._mat[2][1],
                                                 tempMatrix._mat[2][2],
                                                 tempMatrix._mat[2][3],
                                                 tempMatrix._mat[3][0],
                                                 tempMatrix._mat[3][1],
                                                 tempMatrix._mat[3][2],
                                                 tempMatrix._mat[3][3]
            ];
            interface.runJavaScriptFromString(pMatrix);

            projectionMatrixSend = true;
        };

        // since all objects share the same projection matrix, we just take the matrix of the first object and aplly it only one time. We add it as an json object in to the javascropt call.
        //  tempMatrix= tempMarker[0].projectionMatrix;

        stringforTransform = [NSMutableString stringWithFormat:@"update({"];

        // now for all objects we add json elements indicating the name of the marker as the object name and following the model view matrix.
        //
        for (int i = 0; i < nameTemp.size(); i++) {

            tempMatrix = matrixTemp[i];
            
            [stringforTransform appendFormat:@"'%s':[%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf]",
                                             nameTemp[i].c_str(),
                                             tempMatrix._mat[0][0],
                                             tempMatrix._mat[0][1],
                                             tempMatrix._mat[0][2],
                                             tempMatrix._mat[0][3],
                                             tempMatrix._mat[1][0],
                                             tempMatrix._mat[1][1],
                                             tempMatrix._mat[1][2],
                                             tempMatrix._mat[1][3],
                                             tempMatrix._mat[2][0],
                                             tempMatrix._mat[2][1],
                                             tempMatrix._mat[2][2],
                                             tempMatrix._mat[2][3],
                                             tempMatrix._mat[3][0],
                                             tempMatrix._mat[3][1],
                                             tempMatrix._mat[3][2],
                                             tempMatrix._mat[3][3]
            ];
            // formating condition for json.
            if (i < matrixTemp.size() - 1) {
                [stringforTransform appendString:@","];
            }


        }
        //
        // end of string generation.
     //   [stringforTransform appendString:@"}"];

      /*  if(sendAccelerationData == true){
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
        stringforTransform = [NSMutableString stringWithFormat:@"update({'dummy':0})"];

       /* if(sendAccelerationData == true){
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
    for (int i = 0; i < nameCount.size(); i++) {
        NSLog(@"%s %s %s %s, name: %s version: %s  check: %s", nameCount[i][4].c_str(), nameCount[i][5].c_str(), nameCount[i][6].c_str(), nameCount[i][7].c_str(), nameCount[i][0].c_str(),nameCount[i][2].c_str(),nameCount[i][3].c_str());
    }

}

void realityEditor::deviceOrientationChanged(int newOrientation){
  // ofxVuforia & Vuforia = *ofxVuforia::getInstance();
    

    if(newOrientation == 4){
      //  ofSetOrientation((ofOrientation)newOrientation);
    //   Vuforia.setOrientation(OFX_Vuforia_ORIENTATION_LANDSCAPE_RIGHT);
       
    }
    
    if(newOrientation == 3){
       // ofSetOrientation((ofOrientation)newOrientation);
     
      //  Vuforia.setOrientation(OFX_Vuforia_ORIENTATION_LANDSCAPE_LEFT);
      
       
    }
    
}


//--------------------------------------------------------------
void realityEditor::exit() {
    ofxVuforia & Vuforia = *ofxVuforia::getInstance();
    Vuforia.exit();
}


