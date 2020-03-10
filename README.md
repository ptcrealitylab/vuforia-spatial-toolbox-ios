# Vuforia Spatial Toolbox

## Read First
The Vuforia Spatial Toolbox and Vuforia Spatial Edge Server make up a shared research platform
 for exploring spatial computing as a community. This research platform is not an out of the box
  production-ready enterprise solution. Please read the [MPL 2.0 license](LICENSE) before use.

Join the conversations in our [discourse forum](https://forum.spatialtoolbox.vuforia.com) if you
 have questions, ideas want to collaborate or just say hi.

## Installation
How to build and run Vuforia Spatial Toolbox iOS App from your Mac OS Computer.

Note: you need to have [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)
 installed, which you can get on MacOS using:

```bash
sudo gem install cocoapods
```

(Note: these instructions use SSH to clone from Git, but it can also be done with HTTPS)


### Step-by-step Instructions

1. Create a directory to hold the repositories.

```
mkdir -p vuforia-spatial-toolbox
cd vuforia-spatial-toolbox
```

2) Clone the vuforia-spatial-toolbox-ios repo from GitHub. The master branches of all
 repositories should be stable.

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

4) Create an addons folder in the vuforia-spatial-edge-server and clone the
vuforia-spatial-core-addon into that folder.

```
mkdir addons
cd addons
git clone git@github.com:ptcrealitylab/vuforia-spatial-core-addon.git
cd ../
```

5) Run npm install in the vuforia-spatial-edge-server. You may have to go back here and manually
 run npm install for new node packages if they are missing when you try to run the app.

```
npm install
```

6) Clone the vuforia-spatial-toolbox-userinterface into the bin/data directory of the app, and
 rename the directory to "userinterface". This command performs a shallow clone to significantly
  reduce the download size. If you wish to make the shallow clone a deep clone in the future, you
   can run `git fetch --unshallow` in the userinterface directory.

```
cd ../
git clone --shallow-since=2020-03-01 git@github.com:ptcrealitylab/vuforia-spatial-toolbox-userinterface.git
mv vuforia-spatial-toolbox-userinterface userinterface
```


7) Go back to the top level directory of the iOS project, and install its dependencies using
 [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (run
 `sudo gem install cocoapods` first if `pod install` fails)

```
cd ../../
pod install
```

8) Download Vuforia SDK version 8.6.x for iOS from https://developer.vuforia.com/downloads/sdk
 (Click the "Download for iOS" link for *vuforia-sdk-ios-8-6-x.zip*).

- Paste the Vuforia.framework file from the `build` directory of the download into the top level
 of the `vuforia-spatial-toolbox-ios` directory.
- If the latest Vuforia SDK version has been updated beyond this documentation, please consult the
 [forum](https://forum.spatialtoolbox.vuforia.com) for how to proceed.

9) Get a Vuforia Engine license key from http://developer.vuforia.com. 

Create a vuforiaKey.h file in the `vuforia-spatial-toolbox-ios/Vuforia Spatial Toolbox` directory,
 and paste your key into the `vuforiaKey` const. It should look like:

```
//  vuforiaKey.h
//  Licensed from http://developer.vuforia.com

#ifndef vuforiaKey_h
#define vuforiaKey_h

const char* vuforiaKey = "Replace this string with your license key";

#endif /* vuforiaKey_h */
```

10) When these files are in place, open Vuforia Spatial Toolbox.**xcworkspace**. Make sure to
 open the .xcworkspace and not the .xcodeproj, otherwise the dependencies won't load. Make sure
  Xcode is set up with your Apple developer profile for code signing. You should be able to
   compile and run the project (it won't run on the simulator; you need to have an iOS device
    connected).

### Device Compatibility

While this codebase is fundamentally compatible with iPhones and iPads, it has currently only
 been recently tested with iPhones. This has been developed primarily with iOS 11, 12, and 13,
  and with device models iPhone 6S through 11 Pro. If you would like to use this with iPads or
   otherwise improve the compatibility with additional devices and OS versions, your help in
    testing the app on those platforms and identifying bugs will greatly accelerate the path towards
     full compatibility for those devices (you can get involved on our
      [forum](https://forum.spatialtoolbox.vuforia.com)).

### Additional Documentation

Please refer to our
[documentation repository](https://github.com/ptcrealitylab/vuforia-spatial-toolbox-documentation)
for additional tutorials, setup guides, and introductions to various aspects of the system.

In particular, reading about the
[system architecture](https://github.com/ptcrealitylab/vuforia-spatial-toolbox-documentation/blob/master/understandSystem/systemArchitecture.md)
will give you an overview about how the aspects of the system fit together.

### Notes

If your log window is being spammed with `[Process] kill() returned unexpected
error 1` check out [this StackOverflow answer](https://stackoverflow.com/a/58774271).
