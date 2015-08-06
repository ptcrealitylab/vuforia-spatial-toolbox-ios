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

function objectLog(thisKey) {

    var consoleText_ = "";

    consoleText_ += "Object Name: <b>" + thisKey.slice(0, -12);

    if (objectExp[thisKey].loaded === true) {

        consoleText_ += "</b>; Unloading in <b>" + (objectExp[thisKey].visibleCounter / 60).toFixed(1) + " sec.";

    } else {
        consoleText_ += "</b>; Content <b>not</b> loaded<b>";

    }

    consoleText_ += "</b>;  Visible: <b>" + objectExp[thisKey].visible +
    "</b>; MAC: <b>" + thisKey.slice(-12) +
    "</b>; IP: <b>" + objectExp[thisKey].ip +
        // "</b><br>Z: "+objectExp[thisKey].screenZ ;
    "</b>";

    /* for (var key4 in objectExp[thisKey].objectValues) {
     consoleText_ += JSON.stringify(objectExp[thisKey].objectValues[key4]) + "<br>";
     }*/
    return consoleText_;
}

/**********************************************************************************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function generalLog(tempConsoleText) {
    var thisLoop = new Date;
    var fps = 1000 / (thisLoop - globalStates.lastLoop);
    globalStates.lastLoop = thisLoop;


    var GUIElements = 0;

    for (var key3 in objectExp) {

        if (document.getElementById("iframe" + key3)) {
            GUIElements++;
        }

    }

    tempConsoleText += "<br>framerate: <b>" + parseInt(fps) + "</b><br><br>";
    tempConsoleText += "Currently loaded GUI elements: <b>" + GUIElements + "</b><br>";
    tempConsoleText += "Currently loaded Programming elements: <b>" + (document.getElementById("GUI").getElementsByTagName("iframe").length - GUIElements) + "</b><br><br>";
    tempConsoleText += JSON.stringify(globalStates).replace(/,/gi, '<br>');
    document.getElementById("consolelog").style.visibility = "visible";
    document.getElementById("consolelog").innerHTML = tempConsoleText;
    // conalt +=document.getElementById("GUI").innerHTML;
    //  document.getElementById("consolelog").innerText = conalt;
}
