## One Reality App Setup Guide

There is now a **one-reality** branch of the ios project

- without openFrameworks
- with a self-hosted Node.js server



###How to set up:

0. Switch to the **one-reality** branch of the RE-realityeditor-ios git repository

1. Install cocoapods (like npm but for iOS frameworks) in the terminal using: `sudo gem install cocoapods`
2. Run `pod install` in the project directory to set up the modules
3. Open Reality Editor iOS.**xcworkspace** (not the Reality Editor iOS.**xcodeproj** file). This opens a project with all of the modules included. It will look like this:

![Screen Shot 2019-02-14 at 11.52.51 AM](/Users/Benjamin/Desktop/Screen Shot 2019-02-14 at 11.52.51 AM.png)

4. Open the RealityServer directory and download the **miniServerForIos** branch of the RE-server git repository into the folder. The server.js should have the path *RealityServer/RE-server/server.js*
5. Download the **one-reality** branch of the RE-userinterface to the bin/data folder so that the index.html file has the path bin/data/userinterface/index.html
6. Add the vuforiaKey.h file to the Reality Editor iOS directory