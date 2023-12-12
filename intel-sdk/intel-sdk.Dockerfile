# Copyright (C) 2020 Intel Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of Intel Corporation nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


FROM ubuntu:20.04 as sdk

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Brussels \ 
    apt-get install  -y \
    build-essential \
    ocaml \
    ocamlbuild \
    automake \
    autoconf \
    libtool \
    wget \
    python-is-python3 \
    libssl-dev \
    git \
    cmake \
    perl \
    libssl-dev \
    libcurl4-openssl-dev \
    protobuf-compiler \
    libprotobuf-dev \
    debhelper \
    cmake \
    reprepro \
    unzip \
    pkgconf \
    libboost-dev \
    libboost-system-dev \
    libboost-thread-dev \
    protobuf-c-compiler \
    libprotobuf-c-dev \
    lsb-release \
    libsystemd0 \
    python2 \
    nano \
    libssl-dev libcurl4-openssl-dev libprotobuf-dev \
    systemctl

# Clone repo
WORKDIR /
RUN git clone https://github.com/intel/linux-sgx.git linux-sgx
WORKDIR /linux-sgx

# Git cherry picking requires name to be set. 
RUN git config --global user.name "Docker" && git config --global user.email "Docker" 

# Switch to given INTEL_RELEASE
ARG INTEL_RELEASE
RUN git checkout $INTEL_RELEASE

# Start to prepare the bashrc by having some welcome message on start
RUN echo "echo \"Intel SGX SDK Docker container.\" " >> ~/.bashrc
RUN echo "echo \"Release $INTEL_RELEASE.\" " >> ~/.bashrc
RUN echo "echo \"Intel SGX SDK path: /opt/intel/sgxsdk\" " >> ~/.bashrc
RUN echo "echo \"Intel SGX PSW path: /opt/intel/sgxpsw\n\" " >> ~/.bashrc
RUN echo "echo \"The SDK environment file is already sourced. Alternatively you can run this again via: source /opt/intel/sgxsdk/environment\n\" " >> ~/.bashrc
RUN echo "echo \"The PSW is not loaded by default as it needs access to the SGX device.\" " >> ~/.bashrc
RUN echo "echo \"To use the PSW, start the Docker container with --device /dev/sgx/enclave --device /dev/sgx/provision and execute:\" " >> ~/.bashrc
RUN echo "echo \"LD_LIBRARY_PATH=/opt/intel/sgxpsw/aesm /opt/intel/sgxpsw/aesm/aesm_service --no-daemon &\n\" " >> ~/.bashrc

# Prepare for SDK
RUN make preparation
RUN cp external/toolset/ubuntu20.04/* /usr/local/bin
RUN which ar as ld objcopy objdump ranlib

# If we are 2.16, we need to apply a patch for PSW (PATH was incorrect in build script)
RUN sh -c 'if [ "$INTEL_RELEASE" = "sgx_2.16" ]; then git cherry-pick e636b6c; echo "echo \"$INTEL_RELEASE had a bug and commit e636b6c was cherry picked on top of release commit.\n\" " >> ~/.bashrc; fi'

# Build and install SDK
RUN make -j`nproc` sdk_install_pkg DEBUG=1
WORKDIR /opt/intel
RUN sh -c 'echo yes | /linux-sgx/linux/installer/bin/sgx_linux_x64_sdk_*.bin'

# Switch back to install psw
WORKDIR /linux-sgx
RUN make -j`nproc` psw_install_pkg DEBUG=1

# Install psw
WORKDIR /opt/intel
RUN sh -c '/linux-sgx/linux/installer/bin/sgx_linux_x64_psw_*.bin --no-start-aesm'

RUN echo "source /opt/intel/sgxsdk/environment" >> ~/.bashrc

# we don't need the deb files
# RUN  make deb_local_repo

