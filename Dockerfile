# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:12.5.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y build-essential ca-certificates coreutils curl environment-modules gfortran git gpg lsb-release python3 python3-distutils python3-venv unzip zip \
    libssl-dev python-is-python3 \
    cuda-nvcc-12-5 libcurand-dev-12-5 \
    libxinerama-dev libxcursor-dev libxi-dev \
    nano vim \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v0.23.0.tar.gz | tar -xz --strip-components 1 -C /opt/spack

RUN sed -i 's/    granularity: microarchitectures/    granularity: generic/g' /opt/spack/etc/spack/defaults/concretizer.yaml
RUN sed -i '/  all:/a\    target: [x86_64_v3]'  /opt/spack/etc/spack/defaults/packages.yaml
RUN echo "source /opt/spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

SHELL ["/bin/bash", "-l", "-c"]

RUN spack install geant4@11.1.2 \
 && spack uninstall -f -y g4ndl \
 && spack clean -a

RUN spack install boost+system+program_options+regex+filesystem \
 && spack install cmake \
 && spack install nlohmann-json \
 && spack clean -a

RUN spack install mesa ~llvm \
 && spack install glew \
 && spack install glfw \
 && spack install glm \
 && spack install glu \
 && spack clean -a

# Strip all the binaries
#RUN find -L /spack/opt/spack -type f -exec readlink -f '{}' \; | xargs file -i | grep 'charset=binary' | grep 'x-executable\|x-archive\|x-sharedlib' | awk -F: '{print $1}' | xargs strip -S

RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr/local python3 -
RUN poetry self update

RUN sed -i 's/  exec "$@"/  exec "\/bin\/bash" "-c" "$*"/g' /opt/nvidia/nvidia_entrypoint.sh

COPY <<"EOF" /tmp/patch_spack_default_modules.yaml
    include:
      - CPATH
    lib64:
      - LD_LIBRARY_PATH
    lib:
      - LD_LIBRARY_PATH
EOF

RUN sed -i '/  prefix_inspections:/r /tmp/patch_spack_default_modules.yaml' /opt/spack/etc/spack/defaults/modules.yaml
RUN sed -i 's/       autoload: direct/       autoload: none/g'  /opt/spack/etc/spack/defaults/modules.yaml

COPY spack /opt/spack
RUN spack install plog

# Set up non-interactive shells by sourcing all of the scripts in /et/profile.d/
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

