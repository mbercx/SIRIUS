ARG BASE_IMAGE=nvidia/cuda:10.2-devel-ubuntu18.04

FROM $BASE_IMAGE

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="$PATH:/opt/spack/bin"

SHELL ["/bin/bash", "-c"]

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        cmake \
        file \
        g++ \
        gcc \
        gfortran \
        git \
        gnupg2 \
        iproute2 \
        lmod \
        locales \
        lua-posix \
        make \
        python3 \
        python3-pip \
        python3-setuptools \
        tcl \
        unzip \
 && locale-gen en_US.UTF-8 \
 && pip3 install boto3 \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/cmake && \
    curl -Ls https://github.com/Kitware/CMake/releases/download/v3.18.0/cmake-3.18.0-Linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /usr/local/cmake

# We need a patched spack for now to work around environment issues
RUN git clone -b do-not-fail-on-missing-spec --depth 1 https://github.com/haampie/spack.git /opt/spack && \
    rm -rf /opt/spack/.git

# Add our custom spack repo from here
COPY ./spack /user_repo

RUN spack repo add --scope system /user_repo

# Pre-install CUDA and cmake
RUN (echo "packages:" \
&&   echo "  all:" \
&&   echo "    target: [x86_64]" \
&&   echo "    variants:" \
&&   echo "      - 'build_type=Release'" \
&&   echo "      - '+release'" \
&&   echo "  cuda:" \
&&   echo "    paths:" \
&&   echo "      cuda: /usr/local/cuda" \
&&   echo "    buildable: False" \
&&   echo "  cmake:" \
&&   echo "    paths:" \
&&   echo "      cmake: /usr/local/cmake" \
&&   echo "    buildable: False") > /opt/spack/etc/spack/packages.yaml

# Set up the binary cache and trust the public part of our signing key
COPY ./ci/spack/public_key.asc ./public_key.asc
RUN spack mirror add --scope system minio http://148.187.98.133:9000/spack && \
    spack gpg trust ./public_key.asc

# Install dependencies and strip things immediately
# NOTE: this means packages will be stripped in the binary cache...
RUN spack env create ci && \
    spack -e ci install --only=dependencies sirius@develop +cuda ^openblas threads=openmp ^mpich && \
    rm -rf /tmp/* && \
    (find /opt/spack/opt/spack -type f | \
     xargs file -i | \
     grep 'charset=binary' | \
     grep 'x-executable\|x-archive\|x-sharedlib' | \
     awk -F: '{print $1}' | xargs strip -s) || true
