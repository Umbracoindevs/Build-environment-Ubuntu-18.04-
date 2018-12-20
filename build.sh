#!/bin/bash

source deps/ora.sh
source deps/list_input.sh
source deps/text_input.sh

clean_env() {
  make clean
}

build() {
  if [[ "$selected_arch" = "Linux" ]]; then
    build_linux
  elif [[ "$selected_arch" = "Windows 64-bit" ]]; then
    build_windows64
  elif [[ "$selected_arch" = "Windows 32-bit" ]]; then
    build_windows32
  else
    echo "Unknown Architecture"
  fi
}

get_deps() {
  sudo apt -y update
  sudo apt -y upgrade
  sudo apt -y autoremove
  sudo apt-get -y install build-essential libtool autotools-dev autoconf pkg-config libssl-dev libevent-dev automake
  sudo apt-get -y install libboost-all-dev
  sudo add-apt-repository ppa:bitcoin/bitcoin -y
  sudo apt-get update
  sudo apt-get -y install libdb4.8-dev libdb4.8++-dev
  sudo apt-get -y install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
  sudo apt-get -y install git curl
  sudo apt-get -y install qt5-default
  sudo apt-get -y install libssl1.0-dev #LibreSSL Fix for 18.04
}

get_win_deps() {
  sudo apt -y install bsdmainutils
  sudo apt -y install g++-mingw-w64-x86-64 #64 Bit
  sudo apt -y install g++-mingw-w64-i686 mingw-w64-i686-dev #32 Bit
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix #64 Bit
  sudo update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix #32 Bit
}

get_repo() {
  chmod +x ./autogen.sh
  chmod -R 755 *
}

apply_fixes() {
  sed -i -e 's/official_releases/archive/g' depends/packages/qt.mk
  wget https://raw.githubusercontent.com/PIVX-Project/PIVX/master/depends/patches/qt/aarch64-qmake.conf -P depends/patches/qt
  wget https://raw.githubusercontent.com/PIVX-Project/PIVX/master/depends/Makefile -P depends
}

build_linux() {
  echo $(pwd)
  ./autogen.sh
  ./configure
  make
}

build_windows32() {
  PATH=$(echo "$PATH" | sed -e 's/:\/mnt.*//g') # strip out problematic Windows %PATH% imported var
  cd depends
  make HOST=i686-w64-mingw32
  cd ..
  ./autogen.sh # not required when building from tarball
  CONFIG_SITE=$PWD/depends/i686-w64-mingw32/share/config.site ./configure --prefix=/
  make
}

build_windows64() {
  PATH=$(echo "$PATH" | sed -e 's/:\/mnt.*//g') # strip out problematic Windows %PATH% imported var
  cd depends
  make HOST=x86_64-w64-mingw32
  cd ..
  ./autogen.sh # not required when building from tarball
  CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure --prefix=/
  make
}

# Get Script Directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Check for log directory & create
if [[ ! -d logs ]]; then 
  mkdir logs
fi

# Log File
log="logs/build-$(date +%s).txt"

# Distro & Version Check
distro="$(awk -F= '/^NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release)"
version="$(lsb_release -sr)"
echo "Distribution: $distro" > $log
echo "Version: $version" >> $log
if [[ "$version" != "18.04" ]] || [[ "$distro" != "Ubuntu" ]]; then
  echo "Please use Ubuntu 18.04 for easy build"
  exit 1
fi

# Repo Folder Prompt
text_input "What is the repo folder?" repo_folder
if [[ ! -d "$repo_folder" ]]; then 
  echo "Unable to locate provided folder, retry with existing folder."
  exit 1
fi

# Build Arch Prompt
archs=( 'Linux' 'Windows 32-bit' 'Windows 64-bit' )
list_input "What architecture would you like to build?" archs selected_arch

# Make Clean Prompt
yesno=( 'No' 'Yes' )
list_input "Would you like to cleanup?" yesno cleanup_yn

# Build
stty -echo && tput civis

cd "$repo_folder"

if [[ "$cleanup_yn" = "Yes" ]]; then 
  spinner "Cleaning Env" clean_env clean_output
fi

spinner "Getting Default Dependencies" get_deps get_deps_output
if [[ "$selected_arch" = "Windows 64-bit" ]] || [[ "$selected_arch" = "Windows 32-bit" ]]; then
    spinner "Getting Windows Dependencies" get_win_deps get_win_deps_output
fi
spinner "Cloning Repo" get_repo repo_output
spinner "Applying Fixes" apply_fixes fixes_output
spinner "Building $selected_arch" build build_output
tput el

cd "$SCRIPT_DIR"

echo "Clean output: $clean_output" >> $log
echo "Deps output: $get_deps_output" >> $log
echo "Win Deps output: $get_win_deps_output" >> $log
echo "Cloning output: $repo_output" >> $log
echo "Fixes output: $fixes_output" >> $log
echo "Build output: $build_output" >> $log

echo "Build complete."
echo "Log File: $log"

tput cnorm && stty echo