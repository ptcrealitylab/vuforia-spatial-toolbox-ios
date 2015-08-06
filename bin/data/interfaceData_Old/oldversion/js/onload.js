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
/*********************************************************************************************************************
 ******************************************** TODOS *******************************************************************
 **********************************************************************************************************************

 **
 * TODO -
 **

 **********************************************************************************************************************
 ******************************************** onload content **********************************************************
 **********************************************************************************************************************/

/**
 * @desc
 * @param
 * @param
 * @return
 **/

window.onload = function () {
    GUI();

    if (globalStates.platform !== 'iPad' && globalStates.platform !== 'iPhone' && globalStates.platform !== 'iPod') {
        globalStates.platform = false;
    }


    if (globalStates.platform === 'iPhone') {
        document.getElementById("logButtonDiv").style.visibility = "hidden";
        document.getElementById("reloadButtonDiv").style.visibility = "hidden";
        document.getElementById("preferencesButtonDiv").style.bottom = "36px";

        var editingInterface = document.getElementById("content2title");
        editingInterface.style.fontSize = "12px";
        editingInterface.style.left = "38%";
        editingInterface.style.right = "22%";

        editingInterface = document.getElementById("content1title");
        editingInterface.style.fontSize = "12px";
        editingInterface.style.left = "2%";
        editingInterface.style.right = "65%";


        editingInterface = document.getElementById("content2");
        editingInterface.style.fontSize = "9px";
        editingInterface.style.left = "38%";
        editingInterface.style.right = "22%";
        editingInterface.style.bottom = "14%";

         editingInterface = document.getElementById("content11");
        editingInterface.style.fontSize = "12px";
        editingInterface.style.width = "40%";

        editingInterface = document.getElementById("content12");
        editingInterface.style.fontSize = "12px";
        editingInterface.style.width = "60%";


        editingInterface = document.getElementById("content1");
        editingInterface.style.fontSize = "12px";
        editingInterface.style.left = "2%";
        editingInterface.style.right = "65%";
        editingInterface.style.bottom = "14%";

     //   style='position: relative;  float: left; height: 70px; width: 50%;  box-sizing: border-box; padding-top: 13px;padding-left: 13px;



        //   style="position: fixed; left: 5%; top: 13%; right: 58%; bottom: 10%;  -webkit-transform-style: preserve-3d;


    }

    globalCanvas.canvas = document.getElementById('canvas');
    globalCanvas.canvas.width = window.innerWidth;
    globalCanvas.canvas.height = window.innerHeight;
    globalCanvas.context = canvas.getContext('2d');

    if (globalStates.platform) {
        window.location.href = "of://kickoff";
    }

    document.handjs_forcePreventDefault = true;
    globalCanvas.canvas.handjs_forcePreventDefault = true;

    globalCanvas.canvas.addEventListener("pointerdown", canvasPointerDown, false);

    //globalCanvas.canvas.addEventListener("touchstart", MultiTouchCanvasStart, false);
    //globalCanvas.canvas.addEventListener("touchmove", MultiTouchCanvasMove, false);

    document.addEventListener("pointermove", getPossition, false);
    document.addEventListener("pointerdown", getPossition, false);
    document.addEventListener("pointerup", documentPointerUp, false);

    window.addEventListener("message", postMessage, false);

};

/**
 * @desc
 * @param
 * @param
 * @return
 **/

function postMessage(e) {
    console.log(e.data);
    var msgContent = JSON.parse(e.data);
    document.getElementById(msgContent.pos).style.width = msgContent.width;
    document.getElementById(msgContent.pos).style.height = msgContent.height;
    document.getElementById(msgContent.pos).style.top = ((globalStates.width - msgContent.height) / 2);
    document.getElementById(msgContent.pos).style.left = ((globalStates.height - msgContent.width) / 2);

    document.getElementById("iframe" + msgContent.pos).style.width = msgContent.width;
    document.getElementById("iframe" + msgContent.pos).style.height = msgContent.height;
    document.getElementById("iframe" + msgContent.pos).style.top = ((globalStates.width - msgContent.height) / 2);
    document.getElementById("iframe" + msgContent.pos).style.left = ((globalStates.height - msgContent.width) / 2);

};
