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
RUN spack -e esi-env add automake autoconf libtool m4
RUN spack -e esi-env install
RUN spack -e esi-env env activate --sh --dir /opt/spack/var/spack/environments/esi-env > /etc/profile.d/z10_load_spack_environment.sh

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


FROM base AS release

RUN spack -e esi-env add geant4@11.1.2 +opengl +qt
RUN spack -e esi-env env activate \
 && spack load $(spack find --format '{name}{@version}' --explicit) \
 && spack -e esi-env env activate --sh --dir /opt/spack/var/spack/environments/esi-env > /etc/profile.d/z10_load_spack_environment.sh

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_BUILD -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DCMAKE_BUILD_TYPE=Release \
 && cmake --build $OPTICKS_BUILD --parallel --target install


FROM base AS develop

RUN spack -e esi-env install --add root build_type=Debug
RUN spack -e esi-env install --add geant4@11.1.2 +opengl +qt build_type=Debug
RUN spack -e esi-env install && spack clean -a
RUN spack -e esi-env env activate \
 && spack load $(spack find --format '{name}{@version}' --explicit) \
 && spack -e esi-env env activate --sh --dir /opt/spack/var/spack/environments/esi-env > /etc/profile.d/z10_load_spack_environment.sh

# Install RatPac
RUN git clone -b 3.2.0 https://github.com/rat-pac/ratpac-two.git \
 && cmake ratpac-two -B build \
 && cmake --build build/ --parallel

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

# Install Python dependencies
RUN python -m pip install --upgrade pip && pip install -e $OPTICKS_HOME

# need to figure out the location of ptx files in runtime
#RUN spack install --add --reuse --keep-stage eic_opticks build_type=Debug

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_BUILD -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DCMAKE_BUILD_TYPE=Debug \
 && cmake --build $OPTICKS_BUILD --parallel --target install
