#!/bin/sh

INSTALL_DIR=/opt/local/Libraries

if [ "$ARCH" = "arm32" ]; then
  export CROSS_COMPILE=arm-linux-gnueabihf-
else
  export CROSS_COMPILE=aarch64-linux-gnu-
fi

leap_build() {
  echo "$1 $2... "
  INSTALL_NAME=$(echo $1 | tr '[:upper:]' '[:lower:]')
  echo "'$4'"
  if [ ! -d ${INSTALL_DIR}/${INSTALL_NAME}-$2 ] || [ $4 ]; then
    echo "BUILDING"
    export $1_CHANGED=true
    echo $1_CHANGED
    if [ ! -d $1 ]; then
      git clone git@github.com:leapmotion/$1.git
      cd $1
    else
      cd $1
      git fetch
    fi
    git checkout v$2
    if [ -d standard ]; then
      TOOLCHAIN=$(pwd)/standard/toolchain-${ARCH}.cmake
    else
      TOOLCHAIN=$(pwd)/toolchain-${ARCH}.cmake
    fi
    rm -fr build-v$2
    mkdir -p build-v$2
    cd build-v$2
    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN} \
          -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}/${INSTALL_NAME}-$2 \
	  -DCMAKE_PREFIX_PATH:PATH=${INSTALL_DIR} \
          -DCMAKE_BUILD_TYPE=Release \
          -DBOOST_ROOT:PATH=${INSTALL_DIR}/boost_1_55_0 \
          .. && make -j 4 && ./bin/$3 && sudo make install
    cd ../..
  else
    echo "(already installed)"
  fi
}

boost_build() {
  BOOST_VERSION_DOT=$1
  BOOST_VERSION=$(echo $1 | tr \. \_)
  echo "boost $1..."
  INSTALL_PATH=${INSTALL_DIR}/boost_${BOOST_VERSION}
  if [ ! -d ${INSTALL_PATH} ] || [ $2 ]; then
    echo "BUILDING"
    BOOST_TAR_PATH=boost_${BOOST_VERSION}.tar.bz2
    if [ ! -f $BOOST_TAR_PATH ]; then
      curl -sLO http://ncu.dl.sourceforge.net/project/boost/boost/${BOOST_VERSION_DOT}/boost_${BOOST_VERSION}.tar.bz2
    fi
    rm -fr boost_${BOOST_VERSION}
    tar xfj $BOOST_TAR_PATH
    cd boost_${BOOST_VERSION}
    echo "using gcc : arm : ${CROSS_COMPILE}g++-4.9 ;" >> tools/build/v2/user-config.jam
    ./bootstrap.sh
    sudo ./b2 --prefix=${INSTALL_PATH} --build-dir=./tmp link=static threading=multi variant=release cflags=-fPIC cxxflags=-fPIC toolset=gcc-arm target-os=linux --without-mpi --without-python install
    cd ..
  else
    echo "(already installed)"
  fi
}

boost_build 1.55.0
leap_build "autowiring" 1.0.2 "AutowiringTest"
leap_build "leapserial" 0.4.0 "LeapSerialTest"

if [ $autowiring_CHANGED ] || [ $LeapSerial_CHANGED ]; then
 autowiring_LeapSerial_CHANGED=true
fi
leap_build "LeapResource" 0.1.0 "LeapResourceTest" $autowiring_LeapSerial_CHANGED
leap_build "LeapHTTP" 0.1.0 "LeapHTTPTest" $autowiring_CHANGED
leap_build "LeapIPC" 0.1.0 "LeapIPCTest" $autowiring_LeapSerial_CHANGED
