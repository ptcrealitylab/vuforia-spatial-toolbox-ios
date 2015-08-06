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
 * TODO
 **

 **********************************************************************************************************************
 ******************************************** constant settings *******************************************************
 **********************************************************************************************************************/

var httpPort = 8080;
var timeForContentLoaded = 240;

/**********************************************************************************************************************
 ******************************************** global variables  *******************************************************
 **********************************************************************************************************************/

var globalStates = {
    width: window.screen.width,
    height: window.screen.height,
    guiButtonState: true,
    preferencesButtonState: false,
    feezeButtonState: false,
    logButtonState: false,
    editingMode: false,
    guiURL: "",
    platform: navigator.platform,
    lastLoop: 0,
    notLoading: "yes",
    drawDotLine: false,
    drawDotLineX: 0,
    drawDotLineY: 0,
    pointerPosition: [0, 0],
    projectionMatrix: [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ],
    editingModeHaveObject: false,
    angX: 0,
    angY: 0
};

var globalCanvas = {};

var globalObjects = "";

var globalProgram = {
    ObjectA: false,
    locationInA: false,
    ObjectB: false,
    locationInB: false
};

var objectExp = {};

var consoleText = "";
var rotateX = [
    [1, 0, 0, 0],
    [0, -1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];

var testInterlink = {};

/**********************************************************************************************************************
 ******************************************** Constructors ************************************************************
 **********************************************************************************************************************/



/**
 * @constructor
 *//*
 function ObjectExp() {
 this.thisObject = {
 id: "myName0123456789ab",
 ip: "123.456.789.000",
 version: "0.1",
 rotation: "0",
 x: "0",
 y: "0",
 scale: "0",
 screenX : 0,
 screenY : 0,
 matrix3dMemory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
 visible: false,
 visibleCounter:0,
 loaded:false,
 frameSizeX:60,
 frameSizeY:60,
 sockets: 0,
 connected: 0,
 notConnected: 0
 };
 this.objectLinks = {}; // Array of ObjectLink()
 this.objectValues = {}; // Array of ObjectValue()
 this.files = {
 objectFile: "object.json",
 linkFile: "links.json",
 valueFile: "values.json"
 }
 }
 */
/**
 * @desc Constructor for each link
 * @constructor
 */
/*
 function ObjectLink() {
 this.id = null;
 this.ObjectA = null;
 this.locationInA = 0;
 this.ObjectB = null;
 this.locationInB = 0;
 }
 */
/**
 * @desc Constructor for each object value
 * @constructor
 **/
/*
 function ObjectValue() {
 this.id = null;
 this.name = null;
 this.value = null;
 this.rotation = 0;
 this.x = 0;
 this.y = 0;
 this.scale = 0;
 this.screenX = 0;
 this.screenY = 0;
 this.frameSizeX=60;
 this.frameSizeY=60;
 this.plugin = "default";
 this.pluginParameter = null;
 }
 */
