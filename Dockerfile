# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:12.4.0-runtime-ubuntu22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y build-essential ca-certificates coreutils curl gfortran git gpg lsb-release unzip zip python3 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt install -y curl cuda-nvcc-12-4 libcurand-dev-12-4 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/  exec "$@"/  exec "\/bin\/bash" "-c" "$*"/g' /opt/nvidia/nvidia_entrypoint.sh

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v0.23.0.tar.gz | tar -xz --strip-components 1 -C /opt/spack
RUN echo "source /opt/spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

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

SHELL ["/bin/bash", "-l", "-c"]

COPY spack /opt/eic-opticks/spack

RUN spack repo add /opt/eic-opticks/spack
RUN spack env create esi-env
RUN spack -e esi-env add cmake
RUN spack -e esi-env add python py-pip
RUN spack -e esi-env add openssl
RUN spack -e esi-env add glew glfw glm glu nlohmann-json mesa ~llvm
RUN spack -e esi-env add plog
RUN spack -e esi-env add optix_dev@7.7
RUN spack -e esi-env install

ENV BASH_ENV=/etc/bash.nonint
ENV ESI_DIR=/esi
ENV OPTICKS_PREFIX=/opt/eic-opticks
ENV OPTICKS_HOME=${ESI_DIR}/eic-opticks
ENV OPTICKS_BUILD=/opt/eic-opticks/build
ENV SPACK_ENV=/opt/spack/var/spack/environments/esi-env
ENV LD_LIBRARY_PATH=${OPTICKS_PREFIX}/lib:$SPACK_ENV/.spack-env/view/lib:$SPACK_ENV/.spack-env/view/lib64:${LD_LIBRARY_PATH}
ENV PATH=${OPTICKS_PREFIX}/bin:${PATH}
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility

WORKDIR $ESI_DIR

RUN mkdir -p $OPTICKS_HOME && curl -sL https://github.com/BNLNPPS/eic-opticks/archive/0ae57ef923.tar.gz | tar -xz --strip-components 1 -C $OPTICKS_HOME

# Install Python dependencies
RUN python -m pip install --upgrade pip && pip install -e $OPTICKS_HOME


FROM base AS release

RUN spack -e esi-env add geant4@11.1.2 +opengl +qt
RUN spack -e esi-env env activate \
 && spack load $(spack find --format '{name}{@version}' --explicit) \
 && spack -e esi-env env activate --sh --dir /opt/spack/var/spack/environments/esi-env > /etc/profile.d/z10_load_spack_environment.sh

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_BUILD -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DCMAKE_BUILD_TYPE=Release \
 && cmake --build $OPTICKS_BUILD --parallel --target install


FROM base AS develop

RUN spack -e esi-env add geant4@11.1.2 +opengl +qt build_type=Debug
RUN spack -e esi-env add root build_type=Debug
RUN spack -e esi-env install && spack clean -a
RUN spack -e esi-env env activate \
 && spack load $(spack find --format '{name}{@version}' --explicit) \
 && spack -e esi-env env activate --sh --dir /opt/spack/var/spack/environments/esi-env > /etc/profile.d/z10_load_spack_environment.sh

# need to figure out the location of ptx files in runtime
#RUN spack install --add --reuse --keep-stage eic_opticks build_type=Debug

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_BUILD -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DCMAKE_BUILD_TYPE=Debug \
 && cmake --build $OPTICKS_BUILD --parallel --target install
