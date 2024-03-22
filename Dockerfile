# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y build-essential ca-certificates coreutils curl environment-modules gfortran git gpg lsb-release python3 python3-distutils python3-venv unzip zip \
    libglm-dev libglfw3-dev libimgui-dev libglew-dev libglu1-mesa-dev \
    libssl-dev python-is-python3 \
    cuda-nvcc-11-8 libcurand-dev-11-8 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /spack && curl -sL https://github.com/spack/spack/archive/v0.21.0.tar.gz | tar -xz --strip-components 1 -C /spack

RUN echo "source /spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

SHELL ["/bin/bash", "-l", "-c"]

RUN <<EOF
    spack install geant4
    spack install boost+system+program_options+regex+filesystem
    spack install cmake
    spack install nlohmann-json
    spack clean -a
EOF


# Strip all the binaries
#RUN find -L /spack/opt/spack -type f -exec readlink -f '{}' \; | xargs file -i | grep 'charset=binary' | grep 'x-executable\|x-archive\|x-sharedlib' | awk -F: '{print $1}' | xargs strip -S

RUN sed -i 's/  exec "\/bin\/bash"/  exec "\/bin\/bash" "-l"/g' /opt/nvidia/nvidia_entrypoint.sh
RUN sed -i 's/       autoload: direct/\       autoload: none/g'  /spack/etc/spack/defaults/modules.yaml
RUN spack module tcl refresh -y
RUN cp -r /spack/share/spack/modules/$(spack arch) /opt/modules
RUN echo "module use --append /opt/modules" >> /etc/profile.d/z10_load_spack_modules.sh
RUN spack module tcl loads geant4 clhep boost cmake nlohmann-json >> /etc/profile.d/z10_load_spack_modules.sh
RUN rm -fr /spack/share/spack/modules/$(spack arch)

# create a placeholder dir for NVIDIA OptiX
RUN mkdir -p /usr/local/optix

ENV ESI_DIR=/esi-opticks
ENV OPTICKS_HOME=$ESI_DIR/opticks
ENV OPTICKS_PREFIX=/usr/local/opticks
ENV OPTICKS_CUDA_PREFIX=/usr/local/cuda
ENV OPTICKS_OPTIX_PREFIX=/usr/local/optix
ENV OPTICKS_COMPUTE_CAPABILITY=52
ENV PYTHONPATH=${OPTICKS_HOME}

COPY epic $ESI_DIR/epic
COPY opticks $ESI_DIR/opticks
COPY patches $ESI_DIR/patches
COPY .opticks $ESI_DIR/.opticks

WORKDIR $OPTICKS_HOME

RUN mkdir -p $ESI_DIR
RUN echo "source $OPTICKS_HOME/opticks.bash" >> ~/.bash_profile
RUN echo "opticks-" >> ~/.bash_profile

RUN patch -p1 CSGOptiX/OPT.h $ESI_DIR/patches/0001-fix-add-missing-support-for-OptiX-7.6.patch

RUN opticks-full-externals
RUN <<EOF
    source om.bash
    om-(){ echo "skip sourcing om.bash"; }
    om-subs--all(){ deps=(okconf sysrap ana analytic bin CSG qudarap gdxml u4); printf '%s\n' "${deps[@]}"; }
    opticks-full-make
EOF
