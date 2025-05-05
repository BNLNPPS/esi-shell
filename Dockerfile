# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:12.5.0-runtime-ubuntu22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y bzip2 ca-certificates g++ gcc gfortran git gzip lsb-release patch python3 tar unzip xz-utils zstd \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt install -y curl cuda-nvcc-12-5 libcurand-dev-12-5 python-is-python3 python3-pip \
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

RUN python -m pip install -e /opt/eic-opticks

RUN spack repo add /opt/eic-opticks/spack
RUN spack install --only dependencies eic-opticks


FROM base AS release

RUN spack install eic-opticks build_type=Release


FROM base AS develop

RUN spack install --keep-stage eic-opticks build_type=Debug

# Follow instructions at https://docs.nvidia.com/nsight-systems/InstallationGuide/index.html#package-manager-installation
RUN <<"EOF"
 apt update
 apt install -y --no-install-recommends gnupg
 echo "deb http://developer.download.nvidia.com/devtools/repos/ubuntu$(source /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .)/$(dpkg --print-architecture) /" | tee /etc/apt/sources.list.d/nvidia-devtools.list
 apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
 apt update
 apt install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
 apt install -y libqt5x11extras5
 apt install -y libxcb-xinerama0 libxcb-xinerama0-dev
 apt install -y libxkbcommon-x11-0
 apt install -y nsight-systems-cli nsight-systems libgl1-mesa-glx libsm6 libx11-6 libxext6 libxrender1 libxtst6 libxcb1
 apt install -y mesa-utils x11-apps
 apt clean
EOF

COPY nsight-compute-linux-2024.3.2.3-34861637.run .

RUN <<"EOF"
 ./nsight-compute-linux-2024.3.2.3-34861637.run --quiet -- -noprompt
 rm -fr nsight-compute-linux-2024.3.2.3-34861637.run
EOF

RUN apt update && apt install -y gdb
