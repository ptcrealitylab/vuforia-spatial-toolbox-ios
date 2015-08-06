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
 * All ascii characters above must be included in any redistribution.
 *
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 MIT Media Lab / Valentin Heun
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function touchDown(evt) {
    if (!globalStates.editingMode) {
        if (!globalStates.guiButtonState) {
            if (!globalProgram.ObjectA) {
                globalProgram.ObjectA = this.ObjectId;
                globalProgram.locationInA = this.location;
            }
        }
    } else {
        globalStates.editingModeObject = this.ObjectId;
        globalStates.editingModeLocation = this.location;
        globalStates.editingModeHaveObject = true;
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

function falseTouchUp() {
    if (!globalStates.guiButtonState) {
        globalProgram.ObjectA = false;
        globalProgram.locationInA = false;
    }
    globalCanvas.hasContent = true;
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function trueTouchUp() {
    if (!globalStates.guiButtonState) {
        if (globalProgram.ObjectA) {

            var okForNewLink = true;
            var thisTempObject = objectExp[globalProgram.ObjectA];
            var thisTempObjectLinks = thisTempObject.objectLinks;

            globalProgram.ObjectB = this.ObjectId;
            globalProgram.locationInB = this.location;

            // check if connection is with it self
            if (globalProgram.ObjectA === this.ObjectId && globalProgram.locationInA === this.location) {
                okForNewLink = false;
            }

            // todo check that objects are making these checks as well for not producing overlapeses.
            // check if this connection already exists?
            for (var thisSubKey in thisTempObjectLinks) {
                if (thisTempObjectLinks[thisSubKey].ObjectA === globalProgram.ObjectA &&
                    thisTempObjectLinks[thisSubKey].ObjectB === globalProgram.ObjectB &&
                    thisTempObjectLinks[thisSubKey].locationInA === globalProgram.locationInA &&
                    thisTempObjectLinks[thisSubKey].locationInB === globalProgram.locationInB) {
                    okForNewLink = false;
                }

            }

            // check that there is no endless loops through it self or any other connections

            searchL(globalProgram.locationInB,globalProgram.ObjectB,globalProgram.locationInA,globalProgram.ObjectA);

            function searchL(locationInB,ObjectB, locationInA,ObjectA){
                for(var key in objectExp[ObjectB].objectLinks){
                    var Bn = objectExp[ObjectB].objectLinks[key];
                    if(locationInB === Bn.locationInA){
                        if(locationInA === Bn.locationInB && ObjectA === Bn.ObjectB) {
                            okForNewLink = false;
                        }else {
                            searchL(Bn.locationInB, Bn.ObjectB,locationInA,ObjectA);
                        }
                    }
                }
            }


            //  window.location.href = "of://event_" + objectExp[globalProgram.ObjectA].visible;

            if (okForNewLink) {
                var thisKeyId =  uuidTimeShort(); //Math.uuid(17);

                thisTempObjectLinks[thisKeyId] = {
                    ObjectA: globalProgram.ObjectA,
                    locationInA: globalProgram.locationInA,
                    ObjectB: globalProgram.ObjectB,
                    locationInB: globalProgram.locationInB
                };

                // push new connection to objectA
                uploadNewLink(thisTempObject.ip, globalProgram.ObjectA, thisKeyId, thisTempObjectLinks[thisKeyId]);
            }

            // set everything back to false
            globalProgram.ObjectA = false;
            globalProgram.locationInA = false;
            globalProgram.ObjectB = false;
            globalProgram.locationInB = false;
        }
    }
    globalCanvas.hasContent = true;
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function documentPointerUp(evt) {

    if (!globalStates.guiButtonState) {
        falseTouchUp();
        if (!globalProgram.ObjectA && globalStates.drawDotLine) {
            deleteLines(globalStates.drawDotLineX, globalStates.drawDotLineY, evt.clientX, evt.clientY);
        }
        globalStates.drawDotLine = false;
    }
    globalCanvas.hasContent = true;
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function canvasPointerDown(evt) {
    if (!globalStates.guiButtonState && !globalStates.editingMode) {
        if (!globalProgram.ObjectA) {
            globalStates.drawDotLine = true;
            globalStates.drawDotLineX = evt.clientX;
            globalStates.drawDotLineY = evt.clientY;

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

function getPossition(evt) {

    globalStates.pointerPosition = [evt.clientX, evt.clientY];

}


/**
 * @desc
 * @param
 * @param
 * @return
 **/

function MultiTouchStart(evt) {
    evt.preventDefault();
// generate action for all links to be reloaded after upload

    if (globalStates.editingMode && evt.targetTouches.length === 1) {
        globalStates.editingModeObject = this.ObjectId;
        globalStates.editingModeLocation = this.location;
        globalStates.editingModeHaveObject = true;
    }

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function MultiTouchMove(evt) {
    evt.preventDefault();
// generate action for all links to be reloaded after upload

    // console.log(globalStates.editingModeHaveObject + " " + globalStates.editingMode + " " + globalStates.editingModeHaveObject + " " + globalStates.editingMode);

    if (globalStates.editingModeHaveObject && globalStates.editingMode && evt.targetTouches.length === 1) {


        var touch = evt.touches[0];

        globalStates.editingModeObjectX = touch.pageX;
        globalStates.editingModeObjectY = touch.pageY;

        var tempThisObject = {};
        if (globalStates.editingModeObject != globalStates.editingModeLocation) {
            tempThisObject = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation];
        } else {
            tempThisObject = objectExp[globalStates.editingModeObject];
        }


        var tmpM = multiplyMatrix(rotateX, multiplyMatrix(globalObjects[globalStates.editingModeObject], globalStates.projectionMatrix));

        globalStates.angX = toAxisAngle(tmpM)[0];
        globalStates.angY = toAxisAngle(tmpM)[1];

        var screenCoordinateX = tmpM[3][2] * (touch.pageX - globalStates.height / 2);
        var screenCoordinateY = tmpM[3][2] * (touch.pageY - globalStates.width / 2);


        // this functions are somehow ok.... The Projection Matrix gives funky interverences once the angle is sharp.
        // Also I might not have find the right calucaltions


        // todo find right calucaltion
        var possitionY = -Math.sqrt(Math.pow(screenCoordinateY, 2) + Math.pow((screenCoordinateY * globalStates.angY / 2), 2));
        if (screenCoordinateY > 0) {
            possitionY = -possitionY;
        }

        // todo find right calucaltion
        var possitionX = -Math.sqrt(Math.pow(screenCoordinateX, 2) + Math.pow((screenCoordinateX * globalStates.angX / 2), 2));

        if (screenCoordinateX > 0) {
            possitionX = -possitionX;
        }

        var tempObjectMatrix = [
            [tmpM[0][0], tmpM[0][1], tmpM[0][2], tmpM[0][3]],
            [tmpM[1][0], tmpM[1][1], tmpM[1][2], tmpM[1][3]],
            [tmpM[2][0], tmpM[2][1], tmpM[2][2], tmpM[2][3]],
            [possitionX, possitionY, tmpM[3][2], tmpM[3][3]]
        ];

        var invertedObjectMatrix = invertMatrix(tmpM);
        var resultMatrix = multiplyMatrix(tempObjectMatrix, invertedObjectMatrix);

        if(typeof resultMatrix[3][0] === "number" && typeof resultMatrix[3][1] === "number") {
            tempThisObject.x = resultMatrix[3][0];
            tempThisObject.y = resultMatrix[3][1];
        }
    }

    if (globalStates.editingModeHaveObject && globalStates.editingMode && evt.targetTouches.length === 2) {
        scaleEvent(evt.touches[1]);
    }
}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function MultiTouchEnd(evt) {
    evt.preventDefault();
// generate action for all links to be reloaded after upload
    if (globalStates.editingModeHaveObject) {

        console.log("start");
        // this is where it should be send to the object..

        var content = {};
        if (globalStates.editingModeObject === globalStates.editingModeLocation) {
            content.x = objectExp[globalStates.editingModeObject].x;
            content.y = objectExp[globalStates.editingModeObject].y;
            content.scale = objectExp[globalStates.editingModeObject].scale;
        } else {
            content.x = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation].x;
            content.y = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation].y;
            content.scale = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation].scale;
        }
if(typeof content.x === "number" && typeof content.y === "number" && typeof content.scale === "number") {
    postData('http://' + objectExp[globalStates.editingModeObject].ip + ':' + httpPort + '/object/' + globalStates.editingModeObject + "/size/" + globalStates.editingModeLocation, content);
}
        globalStates.editingModeHaveObject = false;
    }
    globalCanvas.hasContent = true;
}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function MultiTouchCanvasStart(evt) {

    evt.preventDefault();
// generate action for all links to be reloaded after upload
    if (globalStates.editingModeHaveObject && globalStates.editingMode && evt.targetTouches.length === 1) {
        var touch = evt.touches[1];

        globalStates.editingScaleX = touch.pageX;
        globalStates.editingScaleY = touch.pageY;
        globalStates.editingScaledistance = Math.sqrt(Math.pow((globalStates.editingModeObjectX - globalStates.editingScaleX), 2) + Math.pow((globalStates.editingModeObjectY - globalStates.editingScaleY), 2));

        var tempThisObject = {};
        if (globalStates.editingModeObject != globalStates.editingModeLocation) {
            tempThisObject = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation];
        } else {
            tempThisObject = objectExp[globalStates.editingModeObject];
        }
        globalStates.editingScaledistanceOld = tempThisObject.scale;
    }

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function MultiTouchCanvasMove(evt) {
    evt.preventDefault();
// generate action for all links to be reloaded after upload
    if (globalStates.editingModeHaveObject && globalStates.editingMode && evt.targetTouches.length === 1) {
        var touch = evt.touches[1];
        //globalStates.editingModeObjectY
        //globalStates.editingScaleX
        scaleEvent(touch)
    }
}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function scaleEvent(touch) {
    var thisRadius = Math.sqrt(Math.pow((globalStates.editingModeObjectX - touch.pageX), 2) + Math.pow((globalStates.editingModeObjectY - touch.pageY), 2));
    var thisScale = (thisRadius - globalStates.editingScaledistance) / 300 + globalStates.editingScaledistanceOld;

    // console.log(thisScale);
    var tempThisObject = {};
    if (globalStates.editingModeObject != globalStates.editingModeLocation) {
        tempThisObject = objectExp[globalStates.editingModeObject].objectValues[globalStates.editingModeLocation];
    } else {
        tempThisObject = objectExp[globalStates.editingModeObject];
    }
    if (thisScale < 0.2)thisScale = 0.2;
    if(typeof thisScale === "number") {
        tempThisObject.scale = thisScale;
    }
    globalCanvas.context.clearRect(0, 0, globalCanvas.canvas.width, globalCanvas.canvas.height);
    //drawRed(globalCanvas.context, [globalStates.editingModeObjectX,globalStates.editingModeObjectY],[touch.pageX,touch.pageY],globalStates.editingScaledistance);
    drawBlue(globalCanvas.context, [globalStates.editingModeObjectX, globalStates.editingModeObjectY], [touch.pageX, touch.pageY], globalStates.editingScaledistance);

    if (thisRadius < globalStates.editingScaledistance) {

        drawRed(globalCanvas.context, [globalStates.editingModeObjectX, globalStates.editingModeObjectY], [touch.pageX, touch.pageY], thisRadius);

    } else {
        drawGreen(globalCanvas.context, [globalStates.editingModeObjectX, globalStates.editingModeObjectY], [touch.pageX, touch.pageY], thisRadius);

    }

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function postData(url, body) {

    var request = new XMLHttpRequest();
    var params = JSON.stringify(body);
    request.open('POST', url, true);
    request.onreadystatechange = function () {
        if (request.readyState == 4) console.log("It worked!");
    };
    request.setRequestHeader("Content-type", "application/json");
    //request.setRequestHeader("Content-length", params.length);
    // request.setRequestHeader("Connection", "close");
    request.send(params);

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function deleteData(url) {

    var request = new XMLHttpRequest();
    request.open('DELETE', url, true);
    request.onreadystatechange = function () {
        if (request.readyState == 4) console.log("It deleted!");
    };
    request.setRequestHeader("Content-type", "application/json");
    //request.setRequestHeader("Content-length", params.length);
    // request.setRequestHeader("Connection", "close");
    request.send();

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function uploadNewLink(ip, thisObjectKey, thisKey, content) {
// generate action for all links to be reloaded after upload
    console.log("sending Link");
    postData('http://' + ip + ':' + httpPort + '/object/' + thisObjectKey + "/link/" + thisKey, content);
    // postData('http://' +ip+ ':' + httpPort+"/", content);

}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function deleteLinkFromObject(ip, thisObjectKey, thisKey) {
// generate action for all links to be reloaded after upload
    console.log("I am deleting a link: " + ip);
    deleteData('http://' + ip + ':' + httpPort + '/object/' + thisObjectKey + "/link/" + thisKey);
}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function addEventHandlers() {

    globalCanvas.canvas.addEventListener("touchstart", MultiTouchCanvasStart, false);
    globalCanvas.canvas.addEventListener("touchmove", MultiTouchCanvasMove, false);

    /*
    for (var thisKey in objectExp) {
        var generalObject2 = objectExp[thisKey];

        if (document.getElementById(thisKey)) {
            var thisObject3 = document.getElementById(thisKey);
          // if (globalStates.guiButtonState) {
             //   thisObject3.style.visibility = "visible";

            if(generalObject2.developer)
            {
                thisObject3.style.display = "initial";
                thisObject3.addEventListener("touchmove", MultiTouchMove, false);
                thisObject3.addEventListener("touchend", MultiTouchEnd, false);
            }
        }

        for (var thisSubKey in generalObject2.objectValues) {
            if (document.getElementById(thisSubKey)) {
                var thisObject2 = document.getElementById(thisSubKey);
                if(generalObject2.developer)
                {
                    thisObject2.style.display = "initial";
                thisObject2.addEventListener("touchmove", MultiTouchMove, false);
                thisObject2.addEventListener("touchend", MultiTouchEnd, false);
                }
            }
        }
    }*/

            for (var thisKey in objectExp) {
                var generalObject2 = objectExp[thisKey];

                if (document.getElementById(thisKey)) {
                    var thisObject3 = document.getElementById(thisKey);
                    if (globalStates.guiButtonState) {
                      //  thisObject3.style.visibility = "visible";
                        thisObject3.style.display = "initial";
                    }
                    thisObject3.addEventListener("touchmove", MultiTouchMove, false);
                    thisObject3.addEventListener("touchend", MultiTouchEnd, false);
                }

                for (var thisSubKey in generalObject2.objectValues) {
                    if (document.getElementById(thisSubKey)) {
                        var thisObject2 = document.getElementById(thisSubKey);
                        thisObject2.style.display = "initial";
                        thisObject2.addEventListener("touchmove", MultiTouchMove, false);
                        thisObject2.addEventListener("touchend", MultiTouchEnd, false);
                    }
                }
            }


}

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function removeEventHandlers() {

    globalCanvas.canvas.removeEventListener("touchstart", MultiTouchCanvasStart, false);
    globalCanvas.canvas.removeEventListener("touchmove", MultiTouchCanvasMove, false);

    for (var thisKey in objectExp) {
        var generalObject2 = objectExp[thisKey];

        if (document.getElementById(thisKey)) {
            var thisObject3 = document.getElementById(thisKey);

            thisObject3.style.display = "none";
            thisObject3.removeEventListener("touchmove", MultiTouchMove, false);
            thisObject3.removeEventListener("touchend", MultiTouchEnd, false);
        }

        for (var thisSubKey in generalObject2.objectValues) {
            if (document.getElementById(thisSubKey)) {
                var thisObject2 = document.getElementById(thisSubKey);

                thisObject2.style.display = "none";
                thisObject2.removeEventListener("touchmove", MultiTouchMove, false);
                thisObject2.removeEventListener("touchend", MultiTouchEnd, false);
            }
        }
    }
}