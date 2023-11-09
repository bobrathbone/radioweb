#!/bin/bash
#set -x
#set -B
# Raspberry Pi Internet Radio Web Interface (O!MPD) setup script
# $Id: setup.sh,v 1.2 2023/11/09 09:48:29 bob Exp $
#
# Author : Bob Rathbone
# Site   : http://www.bobrathbone.com
#
# This program is used to create the Web interface (O!MPD) for radiod 
# if the source has been downloaded from GitHub
# See https://github.com/bobrathbone/radioweb
#
# License: GNU V3, See https://www.gnu.org/copyleft/gpl.html
#
# Disclaimer: Software is provided as is and absolutly no warranties are implied or given.
#        The authors shall not be liable for any loss or damage however caused.
#

BUILD_TOOLS="equivs apt-file lintian"
PKG=radiod
MYSQL_PACKAGES="php${PHP}-gd php${PHP}-mbstring mariadb-server php-mysql php${PHP}-curl "
OS_RELEASE=/etc/os-release
# Amend version of PHP for this OS
PHP=8.2

# Get OS release ID
function release_id
{
    VERSION_ID=$(grep VERSION_ID $OS_RELEASE)
    arr=(${VERSION_ID//=/ })
    ID=$(echo "${arr[1]}" | tr -d '"')
    ID=$(expr ${ID} + 0)
    echo ${ID}
}

# Get OS release name
function osname
{
    VERSION_OSNAME=$(grep VERSION_CODENAME $OS_RELEASE)
    arr=(${VERSION_OSNAME//=/ })
    OSNAME=$(echo "${arr[1]}" | tr -d '"')
    echo ${OSNAME}
}

# Check running as sudo
if [[ "$EUID" -eq 0 ]];then
    echo "Do not run ${0} with sudo"
    exit 1
fi

echo "Radio Web interface package set-up script - $(date)"
echo "Building the radiodweb package for $(osname) release $(release_id)"

echo "Installing build tools ${BUILD_TOOLS}" 
sudo apt-get -y install ${BUILD_TOOLS}

if [[ $? -ne 0 ]]; then
    echo "Installation of ${BUILD_TOOLS} failed - Aborting"
    exit 1
fi

# Install mysql and mariadb packages
echo "Installing mysql  and mariadb packages"
sudo apt-get -y install ${MYSQL_PACKAGES}
if [[ $? -ne 0 ]]; then
    echo "Installation of  ${MYSQL_PACKAGES} failed - Aborting"
    exit 1
fi

# Remove redundant packages
sudo apt -y autoremove

# Update file cache
sudo apt-file update

# Check if this machine is 64-bit or 32 bit
BIT=$(getconf LONG_BIT)
if [[ $BIT == "64" ]]; then
    BUILD="./build64.sh"
    OTHER_PLATFORM="32"
else
    BUILD="./build.sh"
    OTHER_PLATFORM="64"
fi

echo
echo "Now create the radiodweb Debian package with the following command:"
echo "${BUILD}"

echo "(Also run the radioweb build on a ${OTHER_PLATFORM}-bit platform)"

# End of setup script

# :set tabstop=4 shiftwidth=4 expandtab
# :retab
