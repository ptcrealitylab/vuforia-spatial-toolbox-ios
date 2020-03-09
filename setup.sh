#!/bin/bash
set -ex

if ! [ -x "$(command -v pod)" ]; then
  echo "Installing cocoapods"
  sudo gem install cocoapods
fi
pod install

cd bin/data

if ! [ -d "userinterface" ]; then
  echo "Cloning userinterface"
  git clone --shallow-since=2020-03-01 git@github.com:ptcrealitylab/vuforia-spatial-toolbox-userinterface.git userinterface
fi

cd userinterface
git pull
cd ..

if ! [ -d "RE-server" ]; then
  echo "Cloning server"
  git clone git@github.com:ptcrealitylab/vuforia-spatial-edge-server.git
fi

cd vuforia-spatial-edge-server
git pull
if ! [ -d "addons" ]; then
  echo "Cloning addons"
  mkdir addons
  cd addons
  if ! [ -d "vuforia-spatial-core-addon" ]; then
    git clone git@github.com:ptcrealitylab/vuforia-spatial-core-addon.git
  fi
  cd vuforia-spatial-core-addon
  git pull
  npm install
  cd .. # core-addon
  cd .. # addons
fi
npm install
cd ..
