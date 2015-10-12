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
 *              ╦ ╦┬ ┬┌┐ ┬─┐┬┌┬┐  ╔═╗┌┐  ┬┌─┐┌─┐┌┬┐┌─┐
 *              ╠═╣└┬┘├┴┐├┬┘│ ││  ║ ║├┴┐ │├┤ │   │ └─┐
 *              ╩ ╩ ┴ └─┘┴└─┴─┴┘  ╚═╝└─┘└┘└─┘└─┘ ┴ └─┘
 *
 *
 * Created by Valentin on 10/22/14.
 *
 * Copyright (c) 2015 Valentin Heun
 *
 * All ascii characters above must be included in any redistribution.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
/*********************************************************************************************************************
 ******************************************** TODOS *******************************************************************
 **********************************************************************************************************************

 **
 * TODO + Data is loaded from the Object
 * TODO + Generate and delete link
 * TODO + DRAw interface based on Object
 * TODO + Check the coordinates of targets. Incoperate the target size
 * TODO - Check if object is in the right range
 * TODO - add reset button on every target
 * TODO - Documentation before I leave
 * TODO - Arduino Library
 **

/**********************************************************************************************************************
 ******************************************** Data IO *******************************************
 **********************************************************************************************************************/

// Functions to fill the data of the object

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function addHeartbeatObject(beat) {
    /*
     if (globalStates.platform) {
     window.location.href = "of://gotbeat_" + beat.id;
     }
     */
    if (beat.id) {
        if (!objectExp[beat.id]) {
            getData('http://' + beat.ip + ':' + httpPort +'/object/'+beat.id, beat.id, function (req, thisKey) {
                objectExp[thisKey] = req;
               console.log(objectExp[thisKey]);
            });
        }
    }
}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function action(action){
   var thisAction = JSON.parse(action);

    if (thisAction.reloadLink)
    {
        getData('http://' + thisAction.reloadLink.ip + ':' + httpPort +'/object/'+thisAction.reloadLink.id, thisAction.reloadLink.id, function (req, thisKey) {
            objectExp[thisKey].objectLinks = req.objectLinks;
            // console.log(objectExp[thisKey]);
            console.log("got links");
        });

    }

    if (thisAction.reloadObject)
    {
        getData('http://' + thisAction.reloadObject.ip + ':' + httpPort +'/object/'+thisAction.reloadObject.id, thisAction.reloadObject.id, function (req, thisKey) {
            objectExp[thisKey].x = req.x;
            objectExp[thisKey].y = req.y;
            objectExp[thisKey].scale = req.scale;
            objectExp[thisKey].objectValues = req.objectValues;

            // console.log(objectExp[thisKey]);
            console.log("got links");
        });
    }


console.log("found action: "+action);

}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function getData(url, thisKey, callback) {
    var req = new XMLHttpRequest();
    try {
        req.open('GET', url, true);
        // Just like regular ol' XHR
        req.onreadystatechange = function () {
            if (req.readyState === 4) {
                if (req.status >= 200 && req.status < 400) {
                    // JSON.parse(req.responseText) etc.
                    callback(JSON.parse(req.responseText), thisKey)
                } else {
                    // Handle error case
                    console.log("could not load content");
                }
            }
        };
        req.send();

    }
    catch (e) {
        console.log("could not connect to" + url);
    }
}




/**********************************************************************************************************************
 **********************************************************************************************************************/
// set projection matrix

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function setProjectionMatrix(matrix) {
    // globalStates.projectionMatrix = matrix;


    //  generate all transformations for the object that needs to be done ASAP
    var scaleZ = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 2, 0],
        [0, 0, 0, 1]
    ];

    var viewportScaling = [
        [globalStates.height, 0, 0, 0],
        [0, -globalStates.width, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ];

    //   var thisTransform = multiplyMatrix(scaleZ, matrix);
    globalStates.projectionMatrix = multiplyMatrix(multiplyMatrix(scaleZ, matrix), viewportScaling);
    window.location.href = "of://gotProjectionMatrix";


    //   onceTransform();
}


/**********************************************************************************************************************
 ******************************************** update and draw the 3D Interface ****************************************
 **********************************************************************************************************************/
var conalt = "";

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function update(objects) {


    if (globalStates.feezeButtonState == false) {
        globalObjects = objects;
    }
    if (consoleText !== "") {
        consoleText = "";
        document.getElementById("consolelog").innerHTML = "";
    }
    conalt = "";

    if (globalCanvas.hasContent === true) {
        globalCanvas.context.clearRect(0, 0, globalCanvas.canvas.width, globalCanvas.canvas.height);
        globalCanvas.hasContent = false;
    }

    for (var key in objectExp) {
        // if (!objectExp.hasOwnProperty(key)) { continue; }

        var generalObject = objectExp[key];

        if (globalObjects[key]) {

            generalObject.visibleCounter = timeForContentLoaded;
            generalObject.ObjectVisible = true;

            var tempMatrix = multiplyMatrix(rotateX, multiplyMatrix(globalObjects[key], globalStates.projectionMatrix));

            //  var tempMatrix2 = multiplyMatrix(globalObjects[key], globalStates.projectionMatrix);


            //   document.getElementById("controls").innerHTML = (toAxisAngle(tempMatrix2)[0]).toFixed(1)+" "+(toAxisAngle(tempMatrix2)[1]).toFixed(1);


            if (globalStates.guiButtonState || Object.keys(generalObject.objectValues).length === 0) {
                drawTransformed(generalObject, key, tempMatrix, key);
                addElement(generalObject, key, "http://" + generalObject.ip + ":" + httpPort +"/obj/"+key.slice(0, -12)+"/");
            }
            else {
                hideTransformed(generalObject, key, key);
            }



            for (var subKey in generalObject.objectValues) {
                // if (!generalObject.objectValues.hasOwnProperty(subKey)) { continue; }

                var tempValue = generalObject.objectValues[subKey];



                if (!globalStates.guiButtonState) {
                    drawTransformed(tempValue, subKey, tempMatrix, key);
                    addElement(tempValue, subKey, "http://" + generalObject.ip + ":" + httpPort + "/obj/dataPointInterfaces/" + tempValue.plugin + "/", key);
                } else {
                    hideTransformed(tempValue, subKey, key);
                }
            }
        }

        else {
            generalObject.ObjectVisible = false;

            hideTransformed(generalObject, key, key);

            for (var subKey in generalObject.objectValues) {
                // if (!generalObject.objectValues.hasOwnProperty(subKey)) {  continue;  }
                hideTransformed(generalObject.objectValues[subKey], subKey, key);
            }

            killObjects(generalObject, key);
        }

        if (globalStates.logButtonState) {
            consoleText += JSON.stringify(generalObject.objectLinks);
            consoleText += objectLog(key);
        }


    }

    // draw all lines
    if (!globalStates.guiButtonState && !globalStates.editingMode) {
        for (var keyT in objectExp) {
            drawAllLines(objectExp[keyT], globalCanvas.context);

        }
        drawInteractionLines();
    }

    if (globalStates.logButtonState) {
        generalLog(consoleText);
    }

    if (globalStates.preferencesButtonState) {
        addElementInPreferences();
    }
}

/**********************************************************************************************************************
 ******************************************** 3D Transforms & Utilities ***********************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function drawTransformed(thisObject, thisKey, thisTransform2, generalKey) {
    if (globalStates.notLoading !== thisKey && thisObject.loaded === true) {
        if (!thisObject.visible) {
            document.getElementById("thisObject" + thisKey).style.display = 'initial';

            document.getElementById("iframe" + thisKey).style.visibility = 'visible';

            thisObject.visible = true;

            if(generalKey !== thisKey){
                document.getElementById(thisKey).style.visibility = 'visible';
                document.getElementById("text" + thisKey).style.visibility = 'visible';
            }


        }
if(generalKey === thisKey) {
    if (globalStates.editingMode) {
        if(!thisObject.visibleEditing && thisObject.developer){
        thisObject.visibleEditing = true;
        document.getElementById(thisKey).style.visibility = 'visible';

        document.getElementById(thisKey).className = "mainProgram";
    }
    }
}

        var finalMatrixTransform = [
            [thisObject.scale, 0, 0, 0],
            [0, thisObject.scale, 0, 0],
            [0, 0, 1, 0],
            [thisObject.x, thisObject.y, 0, 1]
        ];

        //  thisTransform = multiplyMatrix(objMove, thisTransform);
        var thisTransform = multiplyMatrix(finalMatrixTransform, thisTransform2);

        document.getElementById("thisObject" + thisKey).style.webkitTransform = 'matrix3d(' +
        thisTransform[0][0] + ',' + thisTransform[0][1] + ',' + thisTransform[0][2] + ',' + thisTransform[0][3] + ',' +
        thisTransform[1][0] + ',' + thisTransform[1][1] + ',' + thisTransform[1][2] + ',' + thisTransform[1][3] + ',' +
        thisTransform[2][0] + ',' + thisTransform[2][1] + ',' + thisTransform[2][2] + ',' + thisTransform[2][3] + ',' +
        thisTransform[3][0] + ',' + thisTransform[3][1] + ',' + thisTransform[3][2] + ',' + thisTransform[3][3] + ')';

        // this is for later
        thisObject.screenX = thisTransform[3][0] / thisTransform[3][2] + (globalStates.height / 2);
        thisObject.screenY = thisTransform[3][1] / thisTransform[3][2] + (globalStates.width / 2);
        thisObject.screenZ = thisTransform[3][2];
    }
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function hideTransformed(thisObject, thisKey, generalKey) {
    if (thisObject.visible === true) {
        document.getElementById("thisObject" + thisKey).style.display = 'none';
        document.getElementById("iframe" + thisKey).style.visibility = 'hidden';
       //document.getElementById("iframe" + thisKey).style.display = 'none';
        document.getElementById("text" + thisKey).style.visibility = 'hidden';
     //document.getElementById("text" + thisKey).style.display = 'none';
        thisObject.visible = false;
        thisObject.visibleEditing = false;
        document.getElementById(thisKey).style.visibility = 'hidden';
      //document.getElementById(thisKey).style.display = 'none';

    }

    /*
    if (thisObject.visibleEditing === true) {
        //  console.log(thisKey);
        thisObject.visibleEditing = false;
        document.getElementById(thisKey).style.visibility = 'hidden';
    }*/
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function addElementInPreferences() {

    var htmlContent = "";


    htmlContent += "<div class='Interfaces'" +
    " style='position: relative;  float: left; height: 20px; width: 35%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial;background-color: #333333; -webkit-transform-style: preserve-3d;'>" +
    "Name</div>";
    htmlContent += "<div class='Interfaces'" +
    " style='position: relative;  float: left; height: 20px; width: 30%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial;background-color: #333333; -webkit-transform-style: preserve-3d;'>" +
    "IP</div>";

    htmlContent += "<div class='Interfaces'" +
    " style='position: relative;  float: left; height: 20px; width: 16%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial;background-color: #333333; -webkit-transform-style: preserve-3d; '>" +
    "Version</div>";

    htmlContent += "<div class='Interfaces'" +
    " style='position: relative;  float: left; height: 20px; width: 7%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial; background-color: #333333;-webkit-transform-style: preserve-3d;'>" +
    "I/O</div>";

    htmlContent += "<div class='Interfaces'" +
    " style='position: relative;  float: left; height: 20px; width: 12%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial; background-color: #333333;-webkit-transform-style: preserve-3d;'>" +
    "Links</div>";

    var bgSwitch = false;
    var bgcolor = "";
    for (var keyPref in objectExp) {

        if (bgSwitch) {
            bgcolor = "background-color: #353535;";
            bgSwitch = false;
        } else {
            bgcolor = "background-color: #323232;";
            bgSwitch = true;
        }

        htmlContent += "<div class='Interfaces' id='" +
        "name" + keyPref +
        "' style='position: relative;  float: left; height: 20px; width: 35%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial;" + bgcolor + " -webkit-transform-style: preserve-3d; " +
        "'>" +
        keyPref.slice(0, -12)
        + "</div>";

        htmlContent += "<div class='Interfaces' id='" +
        "name" + keyPref +
        "' style='position: relative;  float: left; height: 20px; width: 30%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial;" + bgcolor + " -webkit-transform-style: preserve-3d; " +
        "'>" +
        objectExp[keyPref].ip
        + "</div>";

        htmlContent += "<div class='Interfaces' id='" +
        "version" + keyPref +
        "' style='position: relative;  float: left; height: 20px; width: 16%; text-align: center; font-family: Helvetica Neue, Helvetica, Arial; " + bgcolor + "-webkit-transform-style: preserve-3d;" +
        "'>" +
        objectExp[keyPref].version
        + "</div>";

        var anzahl = 0;

        for (var subkeyPref2 in objectExp[keyPref].objectValues) {
            anzahl++;
        }

        htmlContent += "<div class='Interfaces' id='" +
        "io" + keyPref +
        "' style='position: relative;  float: left; height: 20px; width: 7%;  text-align: center; font-family: Helvetica Neue, Helvetica, Arial;" + bgcolor + "-webkit-transform-style: preserve-3d;" +
        "'>" +
        anzahl
        + "</div>";


        anzahl = 0;

        for (var subkeyPref in objectExp[keyPref].objectLinks) {
            anzahl++;
        }

        htmlContent += "<div class='Interfaces' id='" +
        "links" + keyPref +
        "' style='position: relative;  float: left; height: 20px; width: 12%; text-align: center;  font-family: Helvetica Neue, Helvetica, Arial;" + bgcolor + "-webkit-transform-style: preserve-3d;" +
        "'>" +
        anzahl
        + "</div>";

    }

    document.getElementById("content2").innerHTML = htmlContent;

}
/*
 <div class='Interfaces'
 style="position: relative; float: left; height: 30px; width: 25%; -webkit-transform-style: preserve-3d;  visibility: visible;
 background-color: #ff3fd4;"></div>
 */

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function addElement(thisObject, thisKey, thisUrl, generalObject) {
    if (globalStates.notLoading !== true && globalStates.notLoading !== thisKey && thisObject.loaded !== true) {

        if (typeof generalObject === 'undefined') {
            generalObject = thisKey;
        }

        thisObject.loaded = true;
        thisObject.visibleEditing = false;
        globalStates.notLoading = thisKey;
        //  window.location.href = "of://objectloaded_" + globalStates.notLoading;

        var addDoc = document.createElement('div');
        addDoc.id = "thisObject" + thisKey;
        addDoc.style.width = globalStates.height + "px";
        addDoc.style.height = globalStates.width + "px";
        addDoc.style.display = "none";
        addDoc.style.border = 0;
        addDoc.className = "main";
        document.getElementById("GUI").appendChild(addDoc);


        var tempAddContent = "<iframe id='iframe" + thisKey + "' onload='on_load(\"" + generalObject + "\",\"" + thisKey + "\")' frameBorder='0' " +
            "style='width:" + thisObject.frameSizeX + "px; height:" + thisObject.frameSizeY + "px;" +
            "top:" + ((globalStates.width - thisObject.frameSizeX) / 2) + "px; left:" + ((globalStates.height - thisObject.frameSizeY) / 2) + "px; visibility: hidden;' " +
            "src='" + thisUrl + "' class='main'></iframe>";

        tempAddContent += "<div id='" + thisKey + "' frameBorder='0' style='width:" + thisObject.frameSizeX + "px; height:" + thisObject.frameSizeY + "px;" +
        "top:" + ((globalStates.width - thisObject.frameSizeX) / 2) + "px; left:" + ((globalStates.height - thisObject.frameSizeY) / 2) + "px; visibility: hidden;' class='mainEditing'></div>" +
        "";

        tempAddContent += "<div id='text" + thisKey + "' frameBorder='0' style='width:5px; height:5px;" +
        "top:" + ((globalStates.width) / 2+thisObject.frameSizeX/2) + "px; left:" + ((globalStates.height - thisObject.frameSizeY) / 2) + "px; visibility: hidden;' class='mainProgram'><font color='white'>"+thisObject.name+"</font></div>" +
        "";

        document.getElementById("thisObject" + thisKey).innerHTML = tempAddContent;
        var theObject = document.getElementById(thisKey);
        theObject.style["touch-action"] = "none";
        theObject["handjs_forcePreventDefault"] = true;
        theObject.addEventListener("pointerdown", touchDown, false);
        theObject.addEventListener("pointerup", trueTouchUp, false);
        if (globalStates.editingMode) {
            if(objectExp[generalObject].developer){
            //theObject.addEventListener("touchstart", MultiTouchStart, false);
            theObject.addEventListener("touchmove", MultiTouchMove, false);
            theObject.addEventListener("touchend", MultiTouchEnd, false);
            theObject.className = "mainProgram";
            }
        }
        theObject.ObjectId = generalObject;
        theObject.location = thisKey;

        if (thisKey !== generalObject) {
            theObject.style.visibility = "visible";
          // theObject.style.display = "initial";
        }
        else {
            theObject.style.visibility = "hidden";
            //theObject.style.display = "none";
        }
    }
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function killObjects(thisObject, thisKey) {


    if (thisObject.visibleCounter > 0) {
        thisObject.visibleCounter--;
    } else if (thisObject.loaded) {
        thisObject.loaded = false;
       // try {
        var tempElementDiv = document.getElementById("thisObject" + thisKey);
            tempElementDiv.parentNode.removeChild(tempElementDiv);
      //  } catch(err){
      //      console.log("err");
      //  }


        for (var subKey in thisObject.objectValues) {
            //  if (!thisObject.objectValues.hasOwnProperty(subKey)) { continue; }
           try{
            tempElementDiv = document.getElementById("thisObject" +subKey);
            tempElementDiv.parentNode.removeChild(tempElementDiv);
      } catch(err){
         console.log("could not find any");
     }
            thisObject.objectValues[subKey].loaded = false;
       }

    }


}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function on_load(generalObject,thisKey) {
    globalStates.notLoading = false;
    // window.location.href = "of://event_test_"+thisKey;

   // console.log("posting Msg");
    var iFrameMessage_ = JSON.stringify({obj: generalObject, pos:thisKey, objectValues:objectExp[generalObject].objectValues});
    document.getElementById("iframe" + thisKey).contentWindow.postMessage(
        iFrameMessage_, '*');
}

function fire(thisKey) {
    // globalStates.notLoading = false;
    window.location.href = "of://event_" + this.location;

}

