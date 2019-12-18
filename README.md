## One Reality App Setup Guide

There is now a **one-reality** branch of the iOS project

- without openFrameworks
- with a self-hosted Node.js server



### How to set up:

0. Make sure you're on the **one-reality** branch of the RE-realityeditor-ios git repository
1. Install cocoapods (like npm but for iOS frameworks) in the terminal using: `sudo gem install cocoapods`
2. Run `pod install` in the project directory to set up the modules.
3. Open the `bin/data` directory and download the **miniServerForIos** branch of the RE-server (https://github.com/PTCInc/RE-server/tree/miniServerForIos) into the folder. The server.js should have the path *bin/data/RE-server/server.js*
4. Download the **one-reality** branch of the RE-userinterface (https://github.com/PTCInc/RE-userinterface/tree/one-reality) to the bin/data folder so that the index.html file has the path _bin/data/userinterface/index.html_
5. Add the private _vuforiaKey.h_ file so that it has the path _Reality Editor iOS/vuforiaKey.h_
6. Add the Vuforia Engine SDK. It is not included in the GitHub repo because it is too large (~100MB), so it should be downloaded separately from https://developer.vuforia.com/downloads/sdk. The resulting download will contain *Vuforia.framework* inside the build/ folder. Copy and paste *Vuforia.framework* into the top level directory of this repository. 
7. Open Reality Editor iOS.**xcworkspace** (not the Reality Editor iOS.**xcodeproj** file). This opens a project with all of the modules included. If everything so far has succeeded, the project structure should look like this, and the project should compile:

![project-structure](README-resources/project-structure.png)

### How to update Vuforia Engine

If a new version of the Vuforia Engine SDK is released (can be downloaded from https://developer.vuforia.com/downloads/sdk), it can take a varying amount of work to update the included SDK version.

In principle, you can just close Xcode, delete the old Vuforia.framework from the project directory, paste in the new Vuforia.framework version, and open Xcode again.

However, sometimes the APIs are not consistent from one version to another. The easiest way to update all integrations is to download the corresponding new version of the Vuforia Samples (Core Features) for iOS:  https://developer.vuforia.com/downloads/samples.

In the *VuforiaSamples/Classes/SampleApplication* directory there is a list of Objective-C/C++ classes that closely mirrors the files in *RE-realityeditor-ios/Reality Editor iOS/Vuforia Application*. To update, you must merge the changes from the new SampleApplication to those files present in the Reality Editor Vuforia Application directory. You can mostly just replace the files with the new versions, but there are several additions to SampleApplicationSession and SampleAppRenderer in particular that must be copied to the new file versions. These changes are mostly isolated to regions surrounded by the following #pragma marks:

```
#pragma mark - Extensions to Vuforia Sample Application

 	... changes ...
 
#pragma mark - 
```
