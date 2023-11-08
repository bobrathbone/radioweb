#!/bin/bash
# set -x
# $Id: buildweb64.sh,v 1.5 2023/11/08 17:27:01 bob Exp $
# Build script for the Raspberry PI radio Web interface Snoopy/O!MPD
# Run this script as user pi and not root

PKG=radiodweb64
VERSION=$(grep ^Version: ${PKG} | awk '{print $2}')
ARCH=$(grep ^Architecture: ${PKG} | awk '{print $2}')
DEBPKG=${PKG}_${VERSION}_${ARCH}.deb
OS_RELEASE=/etc/os-release

# Check we are not running as sudo
if [[ "$EUID" -eq 0 ]];then
        echo "Run this script as user pi and not sudo/root"
        exit 1
fi

# Check if this machine is 64-bit
BIT=$(getconf LONG_BIT)
if [[ ${BIT} != "64" ]]; then
    echo "This build will only run on a 64-bit system"
    echo "This is a ${BIT}-bit system. Use the build.sh script"
    exit 1
fi

# Tar build for Rasbian Buster (Release 12) or later
VERSION_ID=$(grep VERSION_ID ${OS_RELEASE})
SAVEIFS=${IFS}; IFS='='
ID=$(echo ${VERSION_ID} | awk '{print $2}' | sed 's/"//g')
if [[ ${ID} -lt 12 ]]; then
        VERSION=$(grep VERSION= ${OS_RELEASE})
        echo "Raspbian Bookworm (Release 12) or later is required to run this build"
        RELEASE=$(echo ${VERSION} | awk '{print $2 $3}' | sed 's/"//g')
        echo "This is Raspbian ${RELEASE}"
        exit 1
fi
IFS=${SAVEIFS}

WEBPAGES="/var/www/html/*  /usr/lib/cgi-bin/*.cgi"
BUILDFILES="radiodweb radioweb.postinst"
WEBTAR=piradio_web.tar.gz

# Create Web pages tar file
echo "Create web pages tar file ${WEBTAR}"
if [[ -f ${WEBTAR} ]]; then
    echo "${WEBTAR} exists!"
    echo " Do you wish to overwrite this from the live version in /var/www/html"
    echo "tar file with the contents of ${WEBPAGES}"
    echo "(If you made changes in either /var/www/html or /usr/lib/cgi-bin answer Y)"
    echo -n "Overwrite ${WEBTAR} y/n: "
    read ans
    if [[ "${ans}" == 'y' ]]; then
        echo "Creating tarfile ${WEBTAR} from ${WEBPAGES}"
        tar --exclude 'CVS' -cvzf ${WEBTAR} ${WEBPAGES} > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
                echo "Missing input files ${WEBPAGES}"
                exit 1
        fi
    else
        echo "Using existing archive tarfile ${WEBTAR} for package"
    fi
else
    echo "Creating tarfile ${WEBTAR} from ${WEBPAGES}"
    tar --exclude 'CVS' -cvzf ${WEBTAR} ${WEBPAGES} > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
            echo "Missing input files ${WEBPAGES}"
            exit 1
    fi
fi
 
echo "Building package ${PKG} version ${VERSION}"
echo "from input file ${PKG}"
equivs-build ${PKG}

# Remove tar file
# rm -f ${WEBTAR}

echo -n "Check using Lintian y/n: "
read ans
if [[ ${ans} == 'y' ]]; then
	echo "Checking package ${DEBPKG} with lintian"
	lintian ${DEBPKG}
	if [[ $? = 0 ]]
	then
	    dpkg -c ${DEBPKG}
	    echo "Package ${DEBPKG} OK"
	else
	    echo "Package ${DEBPKG} has errors"
	fi
fi

# End of build script
