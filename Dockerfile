# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:12.4.0-runtime-ubuntu22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y bzip2 ca-certificates g++ gcc gfortran git gzip lsb-release patch python3 tar unzip xz-utils zstd \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt update \
 && apt install -y curl cuda-nvcc-12-4 libcurand-dev-12-4 python-is-python3 python3-pip \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v1.0.1.tar.gz | tar -xz --strip-components 1 -C /opt/spack
#RUN sed -i 's/    granularity: microarchitectures/    granularity: generic/g' /opt/spack/etc/spack/defaults/concretizer.yaml
#RUN sed -i '/  all:/a\    target: [x86_64_v3]'  /opt/spack/etc/spack/defaults/base/packages.yaml
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

#RUN mkdir -p /opt/eic-opticks && curl -sL https://github.com/bnlnpps/eic-opticks/archive/refs/heads/main.tar.gz | tar -xz --strip-components 1 -C /opt/eic-opticks

COPY spack /opt/eic-opticks/spack

RUN spack repo add /opt/eic-opticks/spack
#RUN spack install --only dependencies eic-opticks


#FROM base AS release
#
#RUN spack install eic-opticks build_type=Release


#FROM base AS develop
#
#RUN spack install --keep-stage eic-opticks build_type=Debug
#
## Follow instructions at https://docs.nvidia.com/nsight-systems/InstallationGuide/index.html#package-manager-installation
#RUN <<"EOF"
# apt update
# apt install -y --no-install-recommends gnupg
# echo "deb http://developer.download.nvidia.com/devtools/repos/ubuntu$(source /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .)/$(dpkg --print-architecture) /" | tee /etc/apt/sources.list.d/nvidia-devtools.list
# apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
# apt update
# apt install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
# apt install -y libqt5x11extras5
# apt install -y libxcb-xinerama0 libxcb-xinerama0-dev
# apt install -y libxkbcommon-x11-0
# apt install -y nsight-systems-cli nsight-systems libgl1-mesa-glx libsm6 libx11-6 libxext6 libxrender1 libxtst6 libxcb1
# apt install -y mesa-utils x11-apps
# apt clean
#EOF
#
#COPY nsight-compute-linux-2024.3.2.3-34861637.run .
#
#RUN <<"EOF"
# ./nsight-compute-linux-2024.3.2.3-34861637.run --quiet -- -noprompt
# rm -fr nsight-compute-linux-2024.3.2.3-34861637.run
#EOF
#
#RUN apt update && apt install -y gdb

#RUN spack env create esi-env
#RUN echo "spack env activate esi-env" > /etc/profile.d/z10_spack_env_activate_eodev.sh

RUN spack install cmake openssl
RUN spack install glew
RUN spack install glfw
RUN spack install glm
RUN spack install glu
RUN spack install nlohmann-json
RUN spack install mesa
RUN spack install optix-dev@7:
RUN spack install openssl
RUN spack install plog
RUN spack install geant4@11.1.2 +opengl +qt

#RUN spack install environment-modules

#RUN spack install boost

#RUN spack install --add --only dependencies eic-opticks

#RUN spack env create esi-env \
# && spack env activate esi-env \
# && spack add geant4 xerces-c openssl clhep cmake mesa glew glfw glm glu nlohmann-json plog optix-dev mesa-glu \
# && spack install
# && spack load

#RUN spack env create esi-env
#RUN echo "spack env activate esi-env" > /etc/profile.d/z10_spack_env_activate_eodev.sh
#RUN spack install --add geant4 xerces-c openssl clhep cmake mesa glew glfw glm glu nlohmann-json plog optix-dev mesa-glu

RUN apt update && apt install -y environment-modules
RUN apt update && apt install -y python3-venv

#RUN echo "SPACK_MODULES=$(spack location -i environment-modules)" >> /etc/profile.d/z20_load_spack_modules.sh
#RUN echo "source $SPACK_MODULES/init/bash" >> /etc/profile.d/z20_load_spack_modules.sh

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

RUN spack module tcl refresh -y
RUN spack module tcl loads geant4@11.1.2 xerces-c openssl clhep boost cmake mesa glew glfw glm glu nlohmann-json plog optix-dev >> /etc/profile.d/z20_load_spack_modules.sh

ENV OPTICKS_PREFIX=/opt/eic-opticks
ENV OPTICKS_HOME=/src/eic-opticks
ENV OPTICKS_BUILD=/opt/eic-opticks/build
ENV LD_LIBRARY_PATH=${OPTICKS_PREFIX}/lib:/usr/local/lib:${LD_LIBRARY_PATH}
ENV PATH=${OPTICKS_PREFIX}/bin:${PATH}
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility

RUN mkdir -p $OPTICKS_HOME && curl -sL https://github.com/bnlnpps/eic-opticks/archive/refs/heads/main.tar.gz | tar -xz --strip-components 1 -C $OPTICKS_HOME

WORKDIR $OPTICKS_HOME

RUN python -m pip install --upgrade pip && pip install -e .
#RUN python -m venv .venv && source .venv/bin/activate && python -m pip install -e .

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_BUILD -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DOptiX_INSTALL_DIR=/opt/optix -DCMAKE_BUILD_TYPE=Debug \
 && cmake --build $OPTICKS_BUILD --parallel --target install
