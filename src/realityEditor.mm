#include "realityEditor.h"


//--------------------------------------------------------------
void realityEditor::setup() {
    
    //  ofSetFrameRate(120);
    ofBackground(150);

    // images for status in the editor
    imgInterface.load("interface.png");
    imgObject.load("object.png");

    // variables for status
    waitUntil = false;
    onlyOnce = true;
    waitGUI = false;

    // clear temporary folder
    NSArray *tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }

    // initialize vuforia
    ofxQCAR *qcar = ofxQCAR::getInstance();
    qcar->addTarget("target.xml", "target.xml");
    qcar->autoFocusOn();
    qcar->setOrientation(OFX_QCAR_ORIENTATION_LANDSCAPE);
  qcar->setCameraPixelsFlag(true);
    qcar->setMaxNumOfMarkers(5);
    qcar->setup();


    /**********************************************
    INITIALIZING THE INTERFACE
    **********************************************/
    interface.initializeWithCustomDelegate(this);
    interface.loadLocalFile("index");
  //   interface.loadURL("http://html5test.com");
   
    interface.activateView();
    
       cameraImage.allocate(ofGetWidth(), ofGetHeight(), OF_IMAGE_COLOR);
    fbo.allocate(ofGetWidth(), ofGetHeight());
    
        fbo2.allocate(ofGetWidth(), ofGetHeight());
}


/**********************************************
HANDLING REQUESTS FROM JS/HTML (JS->C++)
**********************************************/
void realityEditor::handleCustomRequest(NSString *request) {
    NSLog(@"------------------------------------------------------------%@", request);
    string reqstring([request UTF8String]);

    // if the html interface is loaded kickoff will be send to the c++ code.
    if (reqstring == "kickoff") {
        waitUntil = true;
        NSLog(@"kickoff");
        projectionMatrixSend = false;

        // help to reestablish the arrays when reloaded the interface
        // needs some more work on getting back and forth all the different objects


        // if the message is reload then the interface reloads and all objects are resent to the editor

        if (reloader == true) {

            for (int i = 0; i < nameCount.size(); i++) {
                NSString *jsString3 = [NSString stringWithFormat:@"addHeartbeatObject(%s)", nameCount[i][0].c_str()];
                interface.runJavaScriptFromString(jsString3);
                //   NSLog(@"reload interfaces");
            }
        }
        NSLog(@"reload interfaces");
    }

    if (reqstring == "reload") {
        reloader = true;


    }

    if (reqstring == "freeze") {
        freeze = true;
    }
    if (reqstring == "unfreeze") {
        freeze = false;
        frozeCameraImage = false;
        ofxQCAR *qcar = ofxQCAR::getInstance();
        qcar->resume();
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
            for (int w = 0; w < nameCount[i].size(); w++) {
                loadrunner = nameCount[i][w];

                if (loadrunner == "w") {
                    json.parse(nameCount[i][0]);
                    string tmpDir([NSTemporaryDirectory() UTF8String]);
                    if (w == 1) {
                        if (ofBufferToFile(tmpDir + json["id"].asString() + ".dat", response.data) == true) {
                            nameCount[i][w] = "t";
                            NSLog(@">>copy dat");
                            cons();
                            if (nameCount[i][w + 1] == "t") {
                                nameCount[i][4] = "a";
                                NSLog(@">>activate target");
                                cons();
                            }
                        }
                        break;
                    }
                    if (w == 2) {
                        if (ofBufferToFile(tmpDir + json["id"].asString() + ".xml", response.data) == true) {
                            nameCount[i][w] = "t";
                            NSLog(@">>copy xml");
                            cons();
                            if (nameCount[i][w - 1] == "t") {
                                nameCount[i][4] = "a";
                                NSLog(@">>activate target");
                                cons();
                            }
                        }
                        break;
                    }
                    if (w == 3) {
                        if (ofBufferToFile(tmpDir + json["id"].asString() + ".jpg", response.data) == true) {
                            nameCount[i][w] = "t";
                            NSLog(@">>copy jpg");
                            cons();
                          /*  if (nameCount[i][w - 1] == "t") {
                                nameCount[i][4] = "a";
                                NSLog(@">>activate target");
                                cons();
                            }*/
                        }
                      //    nameCount[i][w] = "t";
                        break;
                    }
                }
            }
        }
    } else {

        // in case the file does not work out, this is the message to call.
        string loadrunner = "";
        for (int i = 0; i < nameCount.size(); i++) {
            for (int w = 0; w < nameCount[i].size(); w++) {
                loadrunner = nameCount[i][w];

                if (loadrunner == "w") {
                    nameCount[i][1] = "n";
                    nameCount[i][2] = "n";
                    nameCount[i][3] = "n";
                    nameCount[i][4] = "n";
                }
            }
        }
        cout << response.status << " " << response.error << endl;
        cons();
    }
}


//--------------------------------------------------------------
void realityEditor::update() {
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
        udpConnection2.Send(message1.c_str(), message1.length());
        ofSleepMillis(50);
        udpConnection2.Send(message1.c_str(), message1.length());
        ofSleepMillis(50);
        udpConnection2.Send(message1.c_str(), message1.length());
        udpConnection2.Close();

        onlyOnce = false;
    }
    
 

    ofxQCAR *qcar = ofxQCAR::getInstance();
    qcar->mutex.lock();
    qcar->update();
    matrixTemp.clear();
    nameTemp.clear();
    //qcar->mutex.lock();
    // tempMarker = qcar->markersFound;
    for (int i = 0; i < qcar->markersFound.size(); i++) {
        matrixTemp.push_back(qcar->markersFound[i].modelViewMatrix);
        nameTemp.push_back(qcar->markersFound[i].markerName);
    }
    
    
    if (!frozeCameraImage && freeze == true) {
        
        
        int cameraW = qcar->getCameraWidth();
        int cameraH = qcar->getCameraHeight();
        unsigned char * cameraPixels = qcar->getCameraPixels();
        if(cameraW > 0 && cameraH > 0 && cameraPixels != NULL) {
            if(cameraImage.isAllocated() == false ) {
                cameraImage.allocate(cameraW, cameraH, OF_IMAGE_GRAYSCALE);
            }
            cameraImage.setFromPixels(cameraPixels, cameraW, cameraH, OF_IMAGE_GRAYSCALE);
            if(qcar->getOrientation() == OFX_QCAR_ORIENTATION_PORTRAIT) {
                cameraImage.rotate90(1);
            } else if(qcar->getOrientation() == OFX_QCAR_ORIENTATION_LANDSCAPE) {
                cameraImage.mirror(true, true);
            }
        }
        // todo, once OF 0.9 is final we have to add the color image again
        // cameraImage.grabScreen(0, 0, ofGetWidth(), ofGetHeight());
        frozeCameraImage = true;
        ofLog() << "+++++++ i get it";
    }
    
    qcar->mutex.unlock();


    if (waitUntil) {
        renderJavascript();
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
}

//--------------------------------------------------------------
void realityEditor::draw() {
    
    ofxQCAR *qcar = ofxQCAR::getInstance();
    

    if (waitUntil) {
// run the messages that process the javascrip view.

        // render the interface
             //  ofLog() << frozeCameraImage << " ++ " << freeze;
   
        if (freeze && frozeCameraImage) {
            cameraImage.draw(0, 0, ofGetWidth(), ofGetHeight());
        }else{
            qcar->draw();
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

  
    
}

void realityEditor::downloadTargets() {

    // file handling

    // check if udp message
    while (udpConnection.Receive(udpMessage, 256) > 0) {
        //NSLog(@">>downloads");
        string message = udpMessage;
        nameExists = false;

        // if message is a valid heartbeat do the following
        if (!json.parse(message.c_str()) || json["id"].empty() || json["ip"].empty()) {
            nameExists = true;
            NSLog(@">>udp message is not a object ping");
                 NSLog(@"%s", json["id"].asString().c_str());
            break;
            
        }

         if(json["id"].asString().size()<13 || json["ip"].asString().size()<7){
                nameExists = true;
                break;
            }


        if (!json["action"].empty()) {
            NSString *jsString4 = [NSString stringWithFormat:@"action('%s')", json["action"].asString().c_str()];
            interface.runJavaScriptFromString(jsString4);
            NSLog(@"%@", jsString4);
        }

        string nameJson = "";
        // NSLog(@">>got something");

        // if the id is valid then check if the name is already in the array.
        if (json["id"].asString().size() > 0) {
            nameJson = json["id"].asString();

            for (int i = 0; i < nameCount.size(); i++) {
                if (nameCount[i][0] == message) {
                    nameExists = true;
                };
            };
        }

        // if name is not in the array generate a new row of an array of strings. and fill them with "f" so that the software knows to process all.
        // remember, the first cell is the full json heart beat, the second indicates the status of the dat file the 3th the status of the xml file and the last cell indicates the status of adding the files to the dictionary.
        if (nameExists == false) {
            vector<string> row;
            row.push_back(message);
            row.push_back("f");
            row.push_back("f");
            row.push_back("f");
             row.push_back("f");
            nameCount.push_back(row);
            NSLog(@">>adding new object");
            cons();
        }
    }

    // process the file downloads
    string loadrunner = "";
    for (int i = 0; i < nameCount.size(); i++) {
        if (loadrunner == "w") {
            break;
        }

        for (int w = 0; w < nameCount[i].size(); w++) {
            loadrunner = nameCount[i][w];
            if (loadrunner == "w") {
                break;
            }
            else if (loadrunner == "f") {
                json.parse(nameCount[i][0]);
                if (w == 1) {

                    string objName = json["id"].asString();
                    objName.erase(objName.end() - 12, objName.end());
                    string sURL = "http://" + json["ip"].asString() + ":8080/obj/" + objName + "/target/target.dat";
                    ofLoadURLAsync(sURL, "done");
                    nameCount[i][w] = "w";
                    loadrunner = "w";
                    NSLog(@">>downloading dat");
                    cons();
                    loadrunner = "w";
                    break;
                }
                if (w == 2) {
                    string objName2 = json["id"].asString();
                    objName2.erase(objName2.end() - 12, objName2.end());
                    string sURL = "http://" + json["ip"].asString() + ":8080/obj/" + objName2 + "/target/target.xml";
                    ofLoadURLAsync(sURL, "done");
                    nameCount[i][w] = "w";
                    loadrunner = "w";
                    NSLog(@">>downloading xml");
                    cons();
                    loadrunner = "w";
                    break;
                }
                 if(w==3){
                     string objName2 = json["id"].asString();
                     objName2.erase(objName2.end() - 12, objName2.end());
                     string sURL = "http://" + json["ip"].asString() + ":8080/obj/" + objName2 + "/target/target.jpg";
                     
                       NSLog(@"%s", sURL.c_str());
                     
                     ofLoadURLAsync(sURL, "done");
                     nameCount[i][w] = "w";
                     loadrunner = "w";
                     NSLog(@">>downloading jpg");
                     cons();
                     loadrunner = "w";
                     break;
                  }
  
            }
                // process the dictonary addon
            else if (loadrunner == "a") {
                string tmpDir([NSTemporaryDirectory() UTF8String]);
                ofxQCAR::getInstance()->addExtraTarget(tmpDir + json["id"].asString() + ".xml");
                nameCount[i][w] = "t";

                NSString *jsString3 = [NSString stringWithFormat:@"addHeartbeatObject(%s)", nameCount[i][0].c_str()];
                interface.runJavaScriptFromString(jsString3);

                loadrunner = "w";
                NSLog(@">>adding target");
                //  ofxQCAR * qcar = ofxQCAR::getInstance();
                // qcar->startExtendedTracking();
                cons();
                loadrunner = "w";
                break;
            }
        }
    }
}

// generate the javascript messages
void realityEditor::renderJavascript() {
    ofxQCAR *qcar = ofxQCAR::getInstance();

    if (nameTemp.size() > 0) {

        if (projectionMatrixSend == false) {
               qcar->mutex.lock();
            tempMatrix = qcar->getProjectionMatrix();
               qcar->mutex.unlock();
            pMatrix = [NSString stringWithFormat:@"setProjectionMatrix([[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf]])",
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

            [stringforTransform appendFormat:@"'%s':[[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf],[%lf,%lf,%lf,%lf]]",
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
        [stringforTransform appendString:@"})"];
    } else {
        stringforTransform = [NSMutableString stringWithFormat:@"update({'dummy':0})"];
    }

    // finally we call the dunction to update the html view.
    interface.runJavaScriptFromString(stringforTransform);
}

// utilities for rendering the conditions of the download process.
void realityEditor::cons() {
    NSLog(@">>cons");
    for (int i = 0; i < nameCount.size(); i++) {
        NSLog(@"%s %s %s %s,%s", nameCount[i][1].c_str(), nameCount[i][2].c_str(), nameCount[i][3].c_str(), nameCount[i][4].c_str(), nameCount[i][0].c_str());
    }

}


//--------------------------------------------------------------
void realityEditor::exit() {
    ofxQCAR::getInstance()->exit();
}


