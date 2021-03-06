#!/bin/bash

#   ***************************************************************************
#     build-qgis.sh - builds android QGIS
#      --------------------------------------
#      Date                 : 01-Jun-2011
#      Copyright            : (C) 2011 by Marco Bernasocchi
#      Email                : marco at bernawebdesign.ch
#   ***************************************************************************
#   *                                                                         *
#   *   This program is free software; you can redistribute it and/or modify  *
#   *   it under the terms of the GNU General Public License as published by  *
#   *   the Free Software Foundation; either version 2 of the License, or     *
#   *   (at your option) any later version.                                   *
#   *                                                                         *
#   ***************************************************************************/

#pass -c as first parameter to perform cmake (configure step)

set -e

EXPERIMENTAL=0
CONFIGURE=0

while getopts ":ec" opt; do
  case $opt in
    e)
      echo "will make Experimental" >&2
      EXPERIMENTAL=1
      ;;
    c)
      echo "Will reconfigure" >&2
      CONFIGURE=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done



source `dirname $0`/config.conf

mkdir -p $QGIS_BUILD_DIR
cd $QGIS_BUILD_DIR

# Reported unused by CMAKE, maybe to be removed
#     CFLAGS
#     CMAKE_TOOLCHAIN_FILE
#     GDAL_CONFIG_PREFER_FWTOOLS_PAT
#     GDAL_CONFIG_PREFER_PATH
#     GEOS_CONFIG_PREFER_PATH
#     GEOS_LIB_NAME_WITH_PREFIX
#     GSL_EXE_LINKER_FLAGS
#     INCLUDE_DIRECTORIES
#     LDFLAGS
#     LIBRARY_OUTPUT_DIRECTORY
#     RUNTIME_OUTPUT_DIRECTORY

MY_CMAKE_FLAGS=" \
-DARM_TARGET=$ANDROID_TARGET_ARCH \
-DBISON_EXECUTABLE=/usr/bin/bison \
-DCFLAGS='$MY_STD_CFLAGS' \
-DCHARSET_LIBRARY=$INSTALL_DIR/lib/libcharset.so \
-DCMAKE_BUILD_TYPE=$BUILD_TYPE \
-DCMAKE_VERBOSE_MAKEFILE=OFF \
-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
-DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/android.toolchain.cmake \
-DEXECUTABLE_OUTPUT_PATH=$INSTALL_DIR/bin \
-DLIBRARY_OUTPUT_DIRECTORY=$INSTALL_DIR/lib \
-DRUNTIME_OUTPUT_DIRECTORY=$INSTALL_DIR/bin \
-DENABLE_TESTS=OFF \
-DEXPAT_INCLUDE_DIR=$INSTALL_DIR/include \
-DEXPAT_LIBRARY=$INSTALL_DIR/lib/libexpat.so \
-DFLEX_EXECUTABLE=/usr/bin/flex \
-DGDAL_CONFIG=$INSTALL_DIR/bin/gdal-config \
-DGDAL_CONFIG_PREFER_FWTOOLS_PAT=/bin_safe \
-DGDAL_CONFIG_PREFER_PATH=$INSTALL_DIR/bin \
-DGDAL_INCLUDE_DIR=$INSTALL_DIR/include \
-DGDAL_LIBRARY=$INSTALL_DIR/lib/libgdal.so \
-DGEOS_CONFIG=$INSTALL_DIR/bin/geos-config \
-DGEOS_CONFIG_PREFER_PATH=$INSTALL_DIR/bin \
-DGEOS_INCLUDE_DIR=$INSTALL_DIR/include \
-DGEOS_LIBRARY=$INSTALL_DIR/lib/libgeos_c.so \
-DGEOS_LIB_NAME_WITH_PREFIX=-lgeos_c \
-DGSL_CONFIG=$INSTALL_DIR/bin/gsl-config \
-DGSL_CONFIG_PREFER_PATH=$INSTALL_DIR/bin \
-DGSL_EXE_LINKER_FLAGS=-Wl,-rpath, \
-DGSL_INCLUDE_DIR=$INSTALL_DIR/include/gsl \
-DICONV_INCLUDE_DIR=$INSTALL_DIR/include \
-DICONV_LIBRARY=$INSTALL_DIR/lib/libiconv.so \
-DINCLUDE_DIRECTORIES=$INSTALL_DIR \
-DLDFLAGS=$MY_STD_LDFLAGS \
-DLIBRARY_OUTPUT_PATH_ROOT=$INSTALL_DIR \
-DNO_SWIG=true \
-DPEDANTIC=OFF \
-DPROJ_INCLUDE_DIR=$INSTALL_DIR/include \
-DPROJ_LIBRARY=$INSTALL_DIR/lib/libproj.so \
-DPOSTGRES_INCLUDE_DIR=$INSTALL_DIR/include \
-DPOSTGRES_LIBRARY=$INSTALL_DIR/lib/libpq.so \
-DQT_MKSPECS_DIR=$QT_ROOT/mkspecs \
-DQT_QMAKE_EXECUTABLE=$QMAKE \
-DQWT_INCLUDE_DIR=$INSTALL_DIR/include \
-DQWT_LIBRARY=$INSTALL_DIR/lib/libqwt.so \
-DSPATIALINDEX_LIBRARY=$INSTALL_DIR/lib/libspatialindex.so
-DWITH_APIDOC=OFF \
-DWITH_ASTYLE=OFF \
-DWITH_BINDINGS=OFF \
-DWITH_DESKTOP=$WITH_DESKTOP \
-DWITH_GLOBE=OFF \
-DWITH_GRASS=OFF \
-DWITH_INTERNAL_QWTPOLAR=ON \
-DWITH_INTERNAL_SPATIALITE=ON \
-DWITH_MAPSERVER=OFF \
-DWITH_MOBILE=$WITH_MOBILE \
-DWITH_POSTGRESQL=ON \
-DWITH_SPATIALITE=ON \
-DWITH_TXT2TAGS_PDF=OFF \
-DGITCOMMAND=`which git` \
-DGIT_MARKER=$QGIS_DIR/.git/index"

#unused flags
#-DSQLITE3_INCLUDE_DIR=$INSTALL_DIR/include \
#-DSQLITE3_LIBRARY=$INSTALL_DIR/lib/libsqlite3.so \

#uncomment the next 2 lines to only get the needed cmake flags echoed
#echo $MY_CMAKE_FLAGS
#exit 0

if [ -n "${QGIS_ANDROID_BUILD_ALL+x}" ]; then
  MY_CMAKE=cmake
else
  MY_CMAKE=ccmake
fi

if [ ! -f CMakeCache.txt ] || [ $CONFIGURE -eq 1 ] ; then
    $MY_CMAKE $MY_CMAKE_FLAGS ..
fi

if [ $EXPERIMENTAL -eq 1 ] ; then
    make -j$CORES Experimental
fi

make -j$CORES install 


GIT_REV=$(git rev-parse HEAD)
#update version file in share
mkdir -p $INSTALL_DIR/files
#echo $GIT_REV > $INSTALL_DIR/files/version.txt
#update apk manifest
sed -i "s|<meta-data android:name=\"android.app.git_rev\" android:value=\".*\"/>|<meta-data android:name=\"android.app.git_rev\" android:value=\"$GIT_REV\"/>|" $APK_DIR/AndroidManifest.xml
