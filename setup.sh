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
  git clone https://github.com/PTCInc/RE-userinterface/ userinterface
fi
cd userinterface
git pull
cd ..

if ! [ -d "RE-server" ]; then
  echo "Cloning server"
  git clone https://github.com/PTCInc/RE-server/
  cd RE-server
  git checkout miniServerForIos
  cd ..
fi
cd RE-server
git pull
npm install
cd ..
