# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y build-essential ca-certificates coreutils curl environment-modules gfortran git gpg lsb-release python3 python3-distutils python3-venv unzip zip \
    libglm-dev libglfw3-dev libimgui-dev libglew-dev libglu1-mesa-dev \
    libssl-dev python-is-python3 \
    cuda-nvcc-11-8 libcurand-dev-11-8 \
    libxinerama-dev libxcursor-dev libxi-dev \
    nano vim \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v0.21.0.tar.gz | tar -xz --strip-components 1 -C /opt/spack

RUN echo "source /opt/spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

SHELL ["/bin/bash", "-l", "-c"]

RUN <<EOF
    spack install geant4
    spack install boost+system+program_options+regex+filesystem
    spack install cmake
    spack install nlohmann-json
    spack uninstall -f -y g4ndl
    spack clean -a
EOF

# Strip all the binaries
#RUN find -L /spack/opt/spack -type f -exec readlink -f '{}' \; | xargs file -i | grep 'charset=binary' | grep 'x-executable\|x-archive\|x-sharedlib' | awk -F: '{print $1}' | xargs strip -S

RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr/local python3 -

RUN sed -i 's/  exec "\/bin\/bash"/  exec "\/bin\/bash" "-l"/g'  /opt/nvidia/nvidia_entrypoint.sh \
 && sed -i 's/  exec "$@"/  exec "\/bin\/bash" "-l" "-c" "$*"/g' /opt/nvidia/nvidia_entrypoint.sh

COPY <<"EOF" /tmp/patch_spack_default_modules.yaml
    include:
      - CPATH
    lib64:
      - LD_LIBRARY_PATH
    lib:
      - LD_LIBRARY_PATH
EOF

RUN sed -i '/  prefix_inspections:/r /tmp/patch_spack_default_modules.yaml' /opt/spack/etc/spack/defaults/modules.yaml
RUN sed -i 's/       autoload: direct/\       autoload: none/g'  /opt/spack/etc/spack/defaults/modules.yaml

RUN spack module tcl refresh -y
RUN cp -r /opt/spack/share/spack/modules/$(spack arch) /opt/modules
RUN echo "module use --append /opt/modules" >> /etc/profile.d/z10_load_spack_modules.sh
RUN spack module tcl loads geant4 xerces-c clhep boost cmake nlohmann-json >> /etc/profile.d/z10_load_spack_modules.sh
RUN rm -fr /opt/spack/share/spack/modules/$(spack arch)

ENV ESI_DIR=/esi
ENV HOME=$ESI_DIR
ENV OPTIX_DIR=/usr/local/optix
ENV OPTICKS_HOME=${ESI_DIR}/opticks
ENV OPTICKS_PREFIX=/usr/local/opticks
ENV OPTICKS_CUDA_PREFIX=/usr/local/cuda
ENV OPTICKS_OPTIX_PREFIX=${OPTIX_DIR}
ENV OPTICKS_COMPUTE_CAPABILITY=89
ENV LD_LIBRARY_PATH=${OPTICKS_PREFIX}/lib:${LD_LIBRARY_PATH}
ENV PATH=${OPTICKS_PREFIX}/lib:${PATH}
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility

WORKDIR $ESI_DIR

COPY .opticks .opticks
COPY epic epic
COPY opticks opticks
COPY patches patches
COPY tests tests
COPY README.md .
COPY NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh .
COPY pyproject.toml .

RUN patch -p1 opticks/sysrap/sevt.py patches/opticks-fix-update-array-dtype-for-numpy-1.26.patch

COPY <<-"EOF" /etc/profile.d/z20_opticks.sh
    source $OPTICKS_HOME/opticks.bash
    opticks-
EOF

RUN mkdir -p $OPTIX_DIR && ./NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh --skip-license --prefix=$OPTIX_DIR
RUN opticks-full
RUN rm -fr $OPTIX_DIR/* $ESI_DIR/NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh

RUN poetry install
