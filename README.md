# Vuforia Spatial Toolbox

## Read First
The Vuforia Spatial Toolbox and Vuforia Spatial Edge Server make up a shared research platform
for exploring spatial computing as a community. This research platform is not an out of the box
production-ready enterprise solution. Please read the [MPL 2.0 license](LICENSE) before use.

Join the conversations in our [discourse forum](https://forum.spatialtoolbox.vuforia.com) if you
have questions, ideas want to collaborate or just say hi.

## Installation
How to build and run Vuforia Spatial Toolbox iOS App from your Mac OS computer from source code.
If you just want to get the app on your phone as quickly as possible, you can simply [download it from the iOS App
 Store](https://apps.apple.com/us/app/vuforia-spatial-toolbox/id1506071001).

1. Clone the vuforia-spatial-toolbox-ios repo from GitHub.

```
git clone https://github.com/ptcrealitylab/vuforia-spatial-toolbox-ios.git
```

2. Initialize the git submodules to get the correct versions of the vuforia-spatial-edge-server
   and the vuforia-spatial-toolbox-userinterface.

```
cd vuforia-spatial-toolbox-ios
git submodule init
git submodule update
```

3. Install some additional dependencies using
   [CocoaPods](https://guides.cocoapods.org/using/getting-started.html). If you don't already have
    CocoaPods installed you should first run `sudo gem install cocoapods`, otherwise `pod install`
    will fail.

```
pod install
```

4. Navigate to the vuforia-spatial-edge-server submodule and run the same commands here to initialize
   its own submodule (vuforia-spatial-core-addon).

```
cd bin/data/vuforia-spatial-edge-server
git submodule init
git submodule update
```

5. Run `npm install` twice: once in vuforia-spatial-edge-server and again in its
   addons/vuforia-spatial-core-addon to install all of its dependencies.

```
npm install
cd addons/vuforia-spatial-core-addon
npm install
```

6. Download the latest Vuforia SDK for iOS from https://developer.vuforia.com/downloads/sdk
   (Click the "Download for iOS" link for *vuforia-sdk-ios-9-4-x.zip*).

   This project was last updated with Vuforia SDK version: `9.6.4`

 - Paste the Vuforia.framework file from the `build` directory of the download into the top level
   of the `vuforia-spatial-toolbox-ios` directory.
 - If the latest Vuforia SDK version has been updated beyond this documentation and you have trouble
   compiling the app, please consult the [forum](https://forum.spatialtoolbox.vuforia.com).

7. Get a Vuforia Engine license key from http://developer.vuforia.com by logging in and navigating
   to `Develop > License Manager > Get Development Key`.

   Create a new file in the `vuforia-spatial-toolbox-ios/Vuforia Spatial Toolbox` directory named
   `vuforiaKey.h` and copy-and-paste the following contents into it. Replace the `vuforiaKey` const
   with your key (a very long, generated sequence of characters):

```
//  vuforiaKey.h
//  Licensed from http://developer.vuforia.com

#ifndef vuforiaKey_h
#define vuforiaKey_h

const char* vuforiaKey = "Replace this string with your license key";

#endif /* vuforiaKey_h */
```

8. When these files are in place, open Vuforia Spatial Toolbox.**xcworkspace**. Make sure to
   open the .xcworkspace and not the .xcodeproj, otherwise the dependencies won't load. Make sure
   Xcode is set up with your Apple developer profile for code signing. You should be able to
   compile and run the project (it won't run on the simulator; you need to have an iOS device
   connected).

### Device Compatibility

While this codebase is fundamentally compatible with iPhones and iPads, it has currently only
been recently tested with iPhones. This has been developed primarily with iOS 12, 13, and 14
and with device models iPhone 6S through 11 Pro. If you would like to use this with iPads or
otherwise improve the compatibility with additional devices and OS versions, your help in testing
the app on those platforms and identifying bugs will greatly accelerate the path towards full
compatibility for those devices (you can get involved on our
[forum](https://forum.spatialtoolbox.vuforia.com)).

If you would like to help developing or testing our Android port (currently in pre-alpha development),
drop us a note in the forum.

### Additional Documentation

Please refer to our [documentation repository](https://github.com/ptcrealitylab/vuforia-spatial-toolbox-documentation)
for additional tutorials, setup guides, and introductions to various aspects of the system.

### Notes

If your log window is being spammed with `[Process] kill() returned unexpected
error 1` check out [this StackOverflow answer](https://stackoverflow.com/a/58774271).
