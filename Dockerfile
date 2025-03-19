# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:12.5.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y bzip2 ca-certificates g++ gcc gfortran git gzip lsb-release patch python3 tar unzip xz-utils zstd \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt install -y curl cuda-nvcc-12-5 libcurand-dev-12-5 python-is-python3 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v0.23.0.tar.gz | tar -xz --strip-components 1 -C /opt/spack

RUN sed -i 's/    granularity: microarchitectures/    granularity: generic/g' /opt/spack/etc/spack/defaults/concretizer.yaml
RUN sed -i '/  all:/a\    target: [x86_64_v3]'  /opt/spack/etc/spack/defaults/packages.yaml
RUN echo "source /opt/spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

SHELL ["/bin/bash", "-l", "-c"]

# Set up non-interactive shells by sourcing all of the scripts in /etc/profile.d/
RUN cat <<"EOF" > /etc/bash.nonint
if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
EOF

RUN cat /etc/bash.nonint >> /etc/bash.bashrc

ENV BASH_ENV=/etc/bash.nonint

RUN mkdir -p /opt/eic-opticks && curl -sL https://github.com/bnlnpps/eic-opticks/archive/refs/heads/main.tar.gz | tar -xz --strip-components 1 -C /opt/eic-opticks

RUN spack repo add /opt/eic-opticks/spack
RUN spack install --only dependencies eic-opticks
RUN spack install eic-opticks
