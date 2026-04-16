#!/usr/bin/env bash

installDeps () { 
  pkgList=$(nimble list --installed)
  if [[ ! $pkgList =~ "kirpi" ]]; then
    echo "Installing: kirpi"
    nimble install kirpi
  else
    echo "kirpi is already installed"
  fi
}

which nimble
if [ $? -eq 0 ]; then
  installDeps
else
  echo "Nimble not found"
fi

if [ ! -d ./bin ]; then 
mkdir ./bin; 
fi

wayland=${#WAYLAND_DISPLAY}
if [ $wayland -gt 0 ]; then
  wayland="-d:wayland"
else
  wayland=""
fi

nim c \
  -d:release \
  $wayland \
  ./src/game.nim

mv ./src/game ./bin
