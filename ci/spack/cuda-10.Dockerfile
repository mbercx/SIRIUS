FROM nvidia/cuda:10.2-devel-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="$PATH:/opt/spack/bin"

SHELL ["/bin/bash", "-c"]

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        file \
        g++ \
        gcc \
        gfortran \
        git \
        make \
        cmake \
        python3 \
        unzip \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/spack/spack.git /opt/spack && rm -rf /opt/spack/.git

COPY ./spack /user_repo

RUN spack repo add --scope system /user_repo

RUN mkdir -p /usr/local/cmake && curl -Ls https://github.com/Kitware/CMake/releases/download/v3.18.0/cmake-3.18.0-Linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /usr/local/cmake

# pre-install cuda
RUN (echo "packages:" \
&&   echo "  all:" \
&&   echo "    target: [x86_64]" \
&&   echo "    variants:" \
&&   echo "      - 'build_type=Release'" \
&&   echo "      - '+release'" \
&&   echo "  cuda:" \
&&   echo "    paths:" \
&&   echo "      cuda@10.2.89%gcc@7.5.0 arch=linux-ubuntu18.04-x86_64: /usr/local/cuda" \
&&   echo "    buildable: False" \
&&   echo "  cmake:" \
&&   echo "    paths:" \
&&   echo "      cmake@3.18.0%gcc@7.5.0 arch=linux-ubuntu18.04-x86_64: /usr/local/cmake" \
&&   echo "    buildable: False") > /opt/spack/etc/spack/packages.yaml

## Install dependencies and strip things immediately
RUN spack install --only=dependencies sirius@develop +cuda ^openblas threads=openmp ^mpich && \
    rm -rf /tmp/* && \
    (find /opt/spack/opt/spack -type f | \
     xargs file -i | \
     grep 'charset=binary' | \
     grep 'x-executable\|x-archive\|x-sharedlib' | \
     awk -F: '{print $1}' | xargs strip -s) || true
