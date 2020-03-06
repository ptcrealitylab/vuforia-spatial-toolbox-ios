# Vuforia Spatial Toolbox

## Installation
How to build and run Vuforia Spatial Toolbox from your computer.

Note: you need to have [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) installed, which you can get on MacOS using:

```bash
sudo gem install cocoapods
```

(Note: these instructions use SSH to clone from Git, but it can also be done with HTTPS)


### Explanation

1. Create a directory to hold the repositories.

```
mkdir -p vuforia-spatial-toolbox
cd vuforia-spatial-toolbox
```

2) Clone the vuforia-spatial-toolbox-ios repo from GitHub. The master branches of all repositories should be stable.

```
git clone git@github.com:ptcrealitylab/vuforia-spatial-toolbox-ios.git
cd vuforia-spatial-toolbox-ios
```

3) Clone the vuforia-spatial-edge-server into the bin/data directory of the app.

```
cd bin/data
git clone git@github.com:ptcrealitylab/vuforia-spatial-edge-server.git
cd vuforia-spatial-edge-server
```

4) Create an addons folder in the vuforia-spatial-edge-server and clone the vuforia-spatial-core-addon into that folder.

```
mkdir addons
cd addons
git clone git@github.com:ptcrealitylab/vuforia-spatial-core-addon.git
cd ../
```

5) Run npm install in the vuforia-spatial-edge-server. You may have to go back here and manually run npm install for new node packages if they are missing when you try to run the app.

```
npm install
```

6) Clone the vuforia-spatial-toolbox-userinterface into the bin/data directory of the app, and rename the directory to userinterface.

```
cd ../
git clone git@github.com:ptcrealitylab/vuforia-spatial-toolbox-userinterface.git
mv vuforia-spatial-toolbox-userinterface userinterface
```


7) Go back to the top level directory of the iOS project, and install its dependencies using [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (run `sudo gem install cocoapods` first if `pod install` fails)

```
cd ../../
pod install
```


8) Download Vuforia SDK version 8.6.7 from https://developer.vuforia.com/downloads/sdk (Click link for *vuforia-sdk-ios-8-6-7.zip (53.67 MB)*)

- paste the Vuforia.framework file from the `build` directory of the download, into the `~/Documents/vuforia-spatial-toolbox/vuforia-spatial-toolbox-ios` directory


9) Get the VuforiaKey.h file from Ben or Valentin, or download a license key from http://developer.vuforia.com. 

- paste VuforiaKey.h into the `~/Documents/vuforia-spatial-toolbox/vuforia-spatial-toolbox-ios/Vuforia Spatial Toolbox` directory 

It should look like:

```
//  vuforiaKey.h
//  Licensed from http://developer.vuforia.com

#ifndef vuforiaKey_h
#define vuforiaKey_h

const char* vuforiaKey = "Replace this string with your license key";

#endif /* vuforiaKey_h */
```

10) When these files are in place, open Vuforia Spatial Toolbox.**xcworkspace**. Make sure to open the .xcworkspace and not the .xcodeproj, otherwise the dependencies won't load. Make sure Xcode is set up with your Apple developer profile for code signing. You should be able to compile and run the project (it won't run on the simulator, need to have an iOS device connected).

### Notes

If your log window is being spammed with `[Process] kill() returned unexpected
error 1` check out [this StackOverflow
answer](https://stackoverflow.com/a/58774271).
