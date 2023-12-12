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

FROM ubuntu:18.04 as sdk

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Brussels \ 
    apt-get install  -y \
    build-essential \
    wget \
    libssl-dev \
    git \
    cmake \
    protobuf-compiler \
    debhelper \
    unzip \
	pkg-config \
	ocaml \
	doxygen
	

# Clone repo
WORKDIR /
RUN git clone https://github.com/openenclave/openenclave.git openenclave
WORKDIR /openenclave

# Git cherry picking requires name to be set. 
RUN git config --global user.name "Docker" && git config --global user.email "Docker" 

# Switch to v060
RUN git checkout v0.6.0
RUN mkdir build

WORKDIR /openenclave/build

# Get correct cmake version
RUN wget https://cmake.org/files/v3.12/cmake-3.12.0-Linux-x86_64.sh
RUN chmod +x ./cmake-3.12.0-Linux-x86_64.sh
RUN ./cmake-3.12.0-Linux-x86_64.sh --skip-license

# Build
RUN ./bin/cmake -DUSE_LIBSGX=OFF ..

RUN make 
RUN make install

RUN echo "source /opt/openenclave/share/openenclave/openenclaverc" >> ~/.bashrc

WORKDIR /openenclave/samples/helloworld
RUN source /opt/openenclave/share/openenclave/openenclaverc && CC=gcc make
