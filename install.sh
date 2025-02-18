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
cmake --install "${LWS_BUILD_DIR}"
ARCH=$(uname -m)
if [[ "$ARCH" == x86_64* ]]; then
    #region libunwind
    pushd "${LIBUNWIND_DIR}"
    make install
    popd
    #endregion libunwind
fi
cmake --install "$PROTON_BUILD_DIR"
#python3 -m pip install --disable-pip-version-check --prefix="$PROTON_INSTALL_DIR/usr" "$(find "$PROTON_BUILD_DIR/python/dist" -name 'python_qpid_proton*.whl')"
cmake --install "${SKUPPER_BUILD_DIR}"
