#!/bin/bash
set -e
# -------------------------------------------------------------------
#   bash ./test-ppa.bash 0.34d
#
# A script to build tomboy-ng PPA packages, gtk2 and Qt5. Download
# this script, run it from your home dir. It depends on a suitable
# FPC and Lazarus installed in root space. 
# If using your own build FPC or Lazarus, you will have to use the
# the prepare scripts. Easy for Debian because it builds only GTK2
# but if you want to build a QT5 PPA, better look at code below.
# Similarly, if you have had a bad build, and need to inc the 
# -1 after the tomboy-ng version number, its manual.
# copyright David Bannon 2021, License unlimited.
# ------------------------------------------------------
# HISTORTY
# 2022-10-05 Now gets version from github and takes eg unstable, focal on CLI
# 

# Debug tool
# USELOCALSCRIPTS="yes"

# VER="33e"
VER="unknown"

STARTDIR="$PWD"/

if [ "$1" == "" ]; then			# sadly, no further checks ....
	echo " ERROR, must provide a distro release name, eg unstable, bionic, focal ..."
	exit 1
fi
RELEASENAME="$1"

# cd ..
# OK, what version are we dealing with then ? Can override git with a local file
# but it will cause all sorts of problems if it does not match when prepare does 
# samething - maybe extend this local file idea and pass something to prepare
# that overrides what it will find in repository ?

if [ "$USELOCALSCRIPTS" == "" ]; then
	rm -f version
	wget https://raw.githubusercontent.com/tomboy-notes/tomboy-ng/master/package/version
fi
VER=`cat version`	# play with this at your peril !
DebVer="PPA""$VER"
rm -Rf "$STARTDIR""Build""$DebVer" "Test""$DebVer" 
mkdir "$STARTDIR""Build""$DebVer"; cd "$STARTDIR""Build""$DebVer"

if [ "$USELOCALSCRIPTS" == "yes" ]; then
	cp ../prepare.ppa .			# same place as version but we have cd....
	cp ../mkcontrol.bash .
else
	wget https://raw.githubusercontent.com/tomboy-notes/tomboy-ng/master/scripts/prepare.ppa
	wget https://raw.githubusercontent.com/tomboy-notes/tomboy-ng/master/scripts/mkcontrol.bash
fi
chmod u+x mkcontrol.bash
bash ./prepare.ppa -D "$RELEASENAME"       # was Bionic for GTK2
cd "tomboy-ng_""$VER""-1" 
debuild -S
cd ..
if [ ! -f "tomboy-ng_""$VER""-1.dsc" ]; then
	echo "======== Failed to make tomboy-ng_""$VER""-1.dsc  exiting ======"
	exit 1
fi

# -------------- OK, now a QT5 version perhaps ? -----------------

if [ "$RELEASENAME" != "bionic" ]; then
	cd "$STARTDIR"
	#DebVer="$DebVer""QT"
	rm -Rf "$STARTDIR""Build""$DebVer"QT "$STARTDIR""Test""$DebVer"QT 
	mkdir "$STARTDIR""Build""$DebVer"QT; cd "$STARTDIR""Build""$DebVer"QT
	if [ "$USELOCALSCRIPTS" == "yes" ]; then
		cp ../prepare.ppa .
		cp ../mkcontrol.bash .
	else
		wget https://raw.githubusercontent.com/tomboy-notes/tomboy-ng/master/scripts/prepare.ppa
		wget https://raw.githubusercontent.com/tomboy-notes/tomboy-ng/master/scripts/mkcontrol.bash
	fi
	chmod u+x mkcontrol.bash
	bash ./prepare.ppa -D "$RELEASENAME" -Q
	cd "tomboy-ng-qt5_""$VER""-1" 
	debuild -S
	cd ..
	if [ ! -f "tomboy-ng-qt5_""$VER""-1.dsc" ]; then
		echo "======== Failed to make dsc file, exiting ======"
		exit 1
	fi
fi

# --------------- OK, lets see what it looks like ---------------
cd ..
cd "$STARTDIR""Build""$DebVer"
mkdir ../Test"$DebVer"
cp *.xz *.gz *.dsc "$STARTDIR"Test"$DebVer" 
cd "$STARTDIR"Test"$DebVer"
dpkg-source -x *.dsc
cd "tomboy-ng-""$VER"               # note '-' at start of ver number, not underscore
dpkg-buildpackage -us  -uc 
cd ..
if [ ! -f "tomboy-ng_""$VER""-1_amd64.deb" ]; then
	echo "======== Failed to make Deb file, exiting ========"
	exit 1
fi
lintian -IiE --pedantic *.changes

if [ "$RELEASENAME" == "bionic" ]; then
	echo "        WARNING - No QT5 for bionic, if there is something there now, it "
	echo "        was there before we started and not valid for this run !!!!"
fi

echo "--------- OK, if it looks OK, go back to each build directoy and run -"
echo "          dput ppa:d-bannon/ppa-tomboy-ng *.changes"
