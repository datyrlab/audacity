#! /bin/bash
	
######################################
# Audacity compile from source Linux Ubuntu 20.04/Debian, mod-script-pipe for python
# https://youtu.be/Xx27GkOyHvE
# 0:00 - intro
# 2:58 - install Audacity from apt repo (demo limitation of apt version)
# 6:17 - start compile from source - install dependent libraries
# 11:02 - create target directory, download source file and uncompress
# 18:00 - create build directory then cmake for both Audacity and wxWidget
# 28:20 - check number of cores to optimize speed of the build
# 30:03 - start build/ compiling - forward through this if you like
# 53:52 - create directory Portable Settings, set permissions and test
# 59:01 - create installer for Audacity
# 01:00:18 - enable modules, mod-script-pipe and make a Python connection
# 01:05:46 - run this script to automate the entire build and install

# script: https://github.com/datyrlab/audacity/blob/master/01-audacity-compile-source-file.sh

# install dependent libraries
# sudo apt install build-essential cmake gcc libsndfile1 libasound2-dev libgtk2.0-dev libgtk-3-dev autoconf automake gettext libid3tag0-dev libmad0-dev libsoundtouch-dev libogg-dev libvorbis-dev libflac-dev libmp3lame0 git git-gui gitk jackd2 libjack-jackd2-dev libavformat-dev ffmpeg autoconf automake libcanberra-gtk-module libcanberra-gtk3-module

# https://twitter.com/datyrlab
#####################################

# variables
#####################################
# location where audacity will be installed, or change it to your preference
directory="/usr/local/share/audacity"
# first download the source file (audacity-minsrc-2.4.2.tar.xz) from https://www.fosshub.com/Audacity.html to your download folder /home/<user>/download
# for older versions, https://www.fosshub.com/Audacity-old.html
# version is file name without the file extension
version="audacity-minsrc-2.4.2"
# set correct path for location of downloaded file... /home/<user>/download
dl_directory="/home/piuser/Downloads"

# dependent libraries
# sudo apt install build-essential cmake gcc libsndfile1 libasound2-dev libgtk2.0-dev libgtk-3-dev autoconf automake gettext libid3tag0-dev libmad0-dev libsoundtouch-dev libogg-dev libvorbis-dev libflac-dev libmp3lame0 git git-gui gitk jackd2 libjack-jackd2-dev libavformat-dev ffmpeg autoconf automake libcanberra-gtk-module libcanberra-gtk3-module
package_list=(

    build-essential        # (g++, gcc, libc6-dev, libc-dev, make)
    cmake                  # cmake --version
    gcc                    # gcc --version  4.9 or later (gcc-7 recommended for Debian / Ubuntu)
    libsndfile1
    libasound2-dev
    libgtk2.0-dev
    libgtk-3-dev
    autoconf 
    automake
    gettext
    libid3tag0-dev
    libmad0-dev
    libsoundtouch-dev
    libogg-dev              # codec
    libvorbis-dev           
    libflac-dev
    libmp3lame0

    #libwxgtk3.0-gtk3-dev   # will install wxWidget in /usr/include/wx-3.0, this is not the right version for audacity - see below
    git                     # needed to auto download wxWidget 3.1.1 to /usr/local/share/audacity/audacity-minsrc-2.4.2/build/cmake-proxies/wxWidgets/wxWidgets 
    git-gui 
    gitk

    jackd2                  # not required, but might be useful later 
    libjack-jackd2-dev      # not required, but might be useful later
    
    libavformat-dev
    ffmpeg                  # if not required then remove from the build below... -Daudacity_use_ffmpeg=loaded

    autoconf 
    automake

    libcanberra-gtk-module  # required or you'll get the an error when running audacity... Failed to load module "canberra-gtk-module"
    libcanberra-gtk3-module
    
    # python3-minimal       # python3 is required, most likely already installed on a Ubuntu/ Debian system

)

# functions
#####################################
function pk_install(){

    if  [[ $1 ]]; then PACKAGE=$1; fi
    #echo $PACKAGE
    
    verify=$(dpkg -s $PACKAGE)
    #echo ${verify}
    
    if [[ ${verify} =~ (Status: install ok) ]]; then
        printf "${PACKAGE} is installed"

    else
        sudo apt install ${PACKAGE} -y

    fi

    unset PACKAGE
    unset verify

}

function audacity_releases(){
    
    # ignore this function, source code for developers is also available on github
    # https://github.com/audacity/audacity/releases
    
    if  [[ $1 ]]; then DIRECTORY=$1; fi    
    if  [[ $2 ]]; then VERSION=$2; fi    

    if [ ! -d ${DIRECTORY} ]; then
        sudo mkdir ${DIRECTORY}
    fi
    
    if [ ! -f "/home/piuser/Downloads/${VERSION}.zip" ]; then
        wget -P /home/piuser/Downloads/ "https://github.com/audacity/audacity/archive/${VERSION}.zip"
    fi

    if [ ! -d ${DIRECTORY}/*${VERSION} ]; then
        unzip "/home/piuser/Downloads/${VERSION}.zip" -d ${DIRECTORY}
    fi
    
}

function audacity_build(){
    
    # https://www.fosshub.com/Audacity.html
    
    if  [[ $1 ]]; then DL_DIRECTORY=$1; fi    
    if  [[ $2 ]]; then DIRECTORY=$2; fi    
    if  [[ $3 ]]; then VERSION=$3; fi    

    if [ ! -d ${DIRECTORY} ]; then
        sudo mkdir ${DIRECTORY}
    fi
    
    if  [[ ${DIRECTORY} ]] && [[ ${VERSION} ]]; then

        # option to auto download needs an update to follow the file link as opposed to downloading the page file
        #if [ ! -f "${DL_DIRECTORY}/${VERSION}.tar.xz" ]; then
        #    wget -P ${DL_DIRECTORY} https://www.fosshub.com/Audacity.html?dwl=${VERSION}.tar.xz
        #fi
        
        if [ -f "${DL_DIRECTORY}/${VERSION}.tar.xz" ]; then
            sudo tar -xJvf "${DL_DIRECTORY}/${VERSION}.tar.xz" -C ${DIRECTORY}

        fi
        
        if [ -d "${DIRECTORY}/${VERSION}" ] && [ ! -d "${DIRECTORY}/${VERSION}/build" ]; then

            cd ${DIRECTORY}/${VERSION}
            sudo mkdir build
            cd build
            sudo cmake -DCMAKE_BUILD_TYPE=Release -Daudacity_use_wxwidgets=local -Daudacity_use_ffmpeg=loaded ..
            
            num_cores=$(cat /proc/cpuinfo | grep processor | wc -l)
            if [[ ${num_cores} -gt 1 ]]; then     
                sudo make j${num_cores}
            else
                sudo make
            fi
        
        else
            
            echo 
            echo "Either download ${VERSION}.tar.xz file from https://www.fosshub.com/Audacity.html, or uninstall existing build"

        fi

    fi

}

function audacity_install(){
    
    if  [[ $1 ]]; then DIRECTORY=$1; fi    
    if  [[ $2 ]]; then VERSION=$2; fi    

    if  [[ ${DIRECTORY} ]] && [[ ${VERSION} ]]; then

        if [ -d "${DIRECTORY}/${VERSION}/build/bin/Release" ]; then
            # Pre-installation test
            cd "${DIRECTORY}/${VERSION}/build/bin/Release"
            sudo mkdir "Portable Settings"
            # folder is required for Audacity to work, here I'm giving it all permissions but you could be more restrictive
            sudo chmod -R 777 "Portable Settings"  
            # test before running installation
            # cd /usr/local/share/audacity/audacity-minsrc-2.4.2/build/bin/Release
            # ./audacity
            
            # installation
            cd "${DIRECTORY}/${VERSION}/build"
            sudo make install

            # to uninstall 
            # cd /usr/local/share/audacity/audacity-minsrc-2.4.2/build/
            # sudo make uninstall
            # or just delete the build folder

        fi

    fi

}
#####################################
# dependent libraries
for package in "${package_list[@]}"; do 
   
    #echo $package
    if [[ $package != "" ]]; then
        echo
        pk_install $package
    fi

done

audacity_build ${dl_directory} ${directory} ${version}
audacity_install ${directory} ${version}

# test python connection
# https://github.com/audacity/audacity/blob/master/scripts/piped-work/pipe_test.py

