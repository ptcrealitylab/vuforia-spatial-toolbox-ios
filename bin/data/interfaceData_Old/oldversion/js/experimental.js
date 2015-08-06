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

var context;
var plainCanvas;
var log;
var pointerDown = {};
var lastPositions = {};
var colors = ["rgb(100, 255, 100)", "rgb(255, 0, 0)", "rgb(0, 255, 0)", "rgb(0, 0, 255)", "rgb(0, 255, 100)", "rgb(10, 255, 255)", "rgb(255, 0, 100)"];

var onPointerMove = function(evt) {
    if (pointerDown[evt.pointerId]) {

        var color = colors[evt.pointerId % colors.length];

        context.strokeStyle = color;

        context.beginPath();
        context.lineWidth = 2;
        context.moveTo(lastPositions[evt.pointerId].x, lastPositions[evt.pointerId].y);
        context.lineTo(evt.clientX, evt.clientY);
        context.closePath();
        context.stroke();

        lastPositions[evt.pointerId] = { x: evt.clientX, y: evt.clientY };
    }
};

var pointerLog = function (evt) {
    var pre = document.querySelector("pre");

    pre.innerHTML = evt.type + "\t\t(" + evt.clientX + ", " + evt.clientY + ")\n" + pre.innerHTML;
};

var onPointerUp = function (evt) {
    pointerDown[evt.pointerId] = false;
    pointerLog(evt);
};

var onPointerDown = function (evt) {
    pointerDown[evt.pointerId] = true;

    lastPositions[evt.pointerId] = { x: evt.clientX, y: evt.clientY };
    pointerLog(evt);
};

var onPointerEnter = function (evt) {
    pointerLog(evt);
};

var onPointerLeave = function (evt) {
    pointerLog(evt);
};

var onPointerOver = function (evt) {
    pointerLog(evt);
};

var onload = function() {
    plainCanvas = document.getElementById("plainCanvas");
    log = document.getElementById("log");

    plainCanvas.width = plainCanvas.clientWidth;
    plainCanvas.height = plainCanvas.clientHeight;

    context = plainCanvas.getContext("2d");

    context.fillStyle = "rgba(50, 50, 50, 1)";
    context.fillRect(0, 0, plainCanvas.width, plainCanvas.height);

    //$("body").on("pointerdown", "canvas", onPointerDown);
    plainCanvas.addEventListener("pointerdown", onPointerDown, false);
    plainCanvas.addEventListener("pointermove", onPointerMove, false);
    plainCanvas.addEventListener("pointerup", onPointerUp, false);
    plainCanvas.addEventListener("pointerout", onPointerUp, false);
    plainCanvas.addEventListener("pointerenter", onPointerEnter, false);
    plainCanvas.addEventListener("pointerleave", onPointerLeave, false);
    plainCanvas.addEventListener("PointerOver", onPointerOver, false);

    //plainCanvas.removeEventListener("pointerdown", onPointerDown);
    //plainCanvas.removeEventListener("PointerMove", onPointerMove);
    //plainCanvas.removeEventListener("PointerUp", onPointerUp);
    //plainCanvas.removeEventListener("PointerOut", onPointerUp);
};

if (document.addEventListener !== undefined) {
    document.addEventListener("DOMContentLoaded", onload, false);
}
;