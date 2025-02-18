#!/usr/bin/bash

#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# https://sipb.mit.edu/doc/safe-shell
set -Eefuxo pipefail
WORKING_DIR="$(pwd)"
SKUPPER_DIR="${WORKING_DIR}/skupper-router"
PROTON_DIR="${WORKING_DIR}/qpid-proton"
LWS_DIR="${WORKING_DIR}/libwebsockets"
LIBUNWIND_DIR="${WORKING_DIR}/libunwind"

LWS_BUILD_DIR="${LWS_DIR}/build"
LWS_INSTALL_DIR="${LWS_DIR}/install"
LIBUNWIND_INSTALL_DIR="${LIBUNWIND_DIR}/install"

PROTON_INSTALL_DIR="${PROTON_DIR}/proton_install"
PROTON_BUILD_DIR="${PROTON_DIR}/build"
SKUPPER_BUILD_DIR="${SKUPPER_DIR}/build"

VERSION="$(cd $SKUPPER_DIR && git describe --tags HEAD)"
# We are installing libwebsockets and libunwind from source
# First, we will install these libraries in /usr/local/lib
# and the include files in /usr/local/include and when skupper-router is compiled
# in the subsequent step, it can find the libraries and include files in /usr/local/
# Second, we install the library *again* in a custom folder so we can
# tar up the usr folder and untar in the Containerfile so that these libraries
# can be used by skupper-router runtime.

#region libwebsockets
# Build libwebsockets library.
# Source folder (cmake -S) is $LWS_DIR
# Build dir (cmake -B) is $LWS_BUILD_DIR
cmake -S "${LWS_DIR}" -B "${LWS_BUILD_DIR}" \
  -DLWS_LINK_TESTAPPS_DYNAMIC=ON \
  -DLWS_WITH_LIBUV=OFF \
  -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
  -DLWS_WITHOUT_BUILTIN_SHA1=ON \
  -DLWS_WITH_STATIC=OFF \
  -DLWS_IPV6=ON \
  -DLWS_WITH_HTTP2=OFF \
  -DLWS_WITHOUT_CLIENT=OFF \
  -DLWS_WITHOUT_SERVER=OFF \
  -DLWS_WITHOUT_TESTAPPS=ON \
  -DLWS_WITHOUT_TEST_SERVER=ON \
  -DLWS_WITHOUT_TEST_SERVER_EXTPOLL=ON \
  -DLWS_WITHOUT_TEST_PING=ON \
  -DLWS_WITHOUT_TEST_CLIENT=ON
cmake --build "${LWS_BUILD_DIR}" --parallel "$(nproc)" --verbose
#cmake --install "${LWS_BUILD_DIR}"

# Read about DESTDIR here - https://www.gnu.org/prep/standards/html_node/DESTDIR.html
#DESTDIR="${LWS_INSTALL_DIR}" cmake --install "${LWS_BUILD_DIR}"
#ar -z -C "${LWS_INSTALL_DIR}" -cf /libwebsockets-image.tar.gz usr
#endregion libwebsockets

ARCH=$(uname -m)
if [[ "$ARCH" == x86_64* ]]; then
    #region libunwind
    echo "Arch is x86_64, compiling libunwind"
    pushd "${LIBUNWIND_DIR}"
    autoreconf -i
    ./configure
    make
    #make install
    popd
    #endregion libunwind
else
   echo "Arch is NOT x86_64, NOT compiling libunwind"
fi


# Before installing qpid-proton, install the python build package
python3 -m pip install --disable-pip-version-check build

cmake -S "${PROTON_DIR}" -B "${PROTON_BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DENABLE_LINKTIME_OPTIMIZATION=ON \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DBUILD_TLS=ON -DSSL_IMPL=openssl -DBUILD_STATIC_LIBS=ON -DBUILD_BINDINGS=python \
  -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF \
  -DCMAKE_INSTALL_PREFIX=${PROTON_BUILD_DIR}/install

cmake --build "${PROTON_BUILD_DIR}" --verbose

# `cmake --install` Proton for the build image only as the router links it statically
# Proton Python for the run image is installed later
#cmake --install "$PROTON_BUILD_DIR"

cmake -S "${SKUPPER_DIR}" -B "${SKUPPER_BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DProton_USE_STATIC_LIBS=ON \
    -DProton_DIR="$PROTON_BUILD_DIR/install/lib64/cmake/Proton" \
    -DBUILD_TESTING=OFF \
    -DVERSION="${VERSION}" \
    -DCMAKE_INSTALL_PREFIX=/usr
    
cmake --build "${SKUPPER_BUILD_DIR}" --verbose

# Install Proton Python
python3 -m pip install --disable-pip-version-check --prefix="$PROTON_INSTALL_DIR/usr" "$(find "$PROTON_BUILD_DIR/python/dist" -name 'python_qpid_proton*.whl')"
#tar -z -C "${PROTON_INSTALL_DIR}" -cf /qpid-proton-image.tar.gz usr

#DESTDIR="${SKUPPER_DIR}/staging/" cmake --install "${SKUPPER_BUILD_DIR}"

#tar -z -C "${SKUPPER_DIR}/staging/" -cf /skupper-router-image.tar.gz usr etc
#endregion qpid-proton and skupper-router
