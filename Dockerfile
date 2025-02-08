# syntax=docker/dockerfile:latest

FROM nvcr.io/nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Spack package manager
RUN apt update \
 && apt install -y build-essential ca-certificates coreutils curl environment-modules gfortran git gpg lsb-release python3 python3-distutils python3-venv unzip zip \
    libssl-dev python-is-python3 \
    cuda-nvcc-11-8 libcurand-dev-11-8 \
    libxinerama-dev libxcursor-dev libxi-dev \
    nano vim \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/spack && curl -sL https://github.com/spack/spack/archive/v0.23.0.tar.gz | tar -xz --strip-components 1 -C /opt/spack

RUN sed -i 's/    granularity: microarchitectures/    granularity: generic/g' /opt/spack/etc/spack/defaults/concretizer.yaml
RUN sed -i '/  all:/a\    target: [x86_64_v3]'  /opt/spack/etc/spack/defaults/packages.yaml
RUN echo "source /opt/spack/share/spack/setup-env.sh" > /etc/profile.d/z09_source_spack_setup.sh

SHELL ["/bin/bash", "-l", "-c"]

RUN spack install geant4 \
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

RUN spack module tcl refresh -y
RUN cp -r /opt/spack/share/spack/modules/linux-ubuntu22.04-x86_64_v3 /opt/modules
RUN echo "module use --append /opt/modules" >> /etc/profile.d/z10_load_spack_modules.sh
RUN spack module tcl loads geant4 xerces-c openssl clhep boost cmake mesa glew glfw glm glu nlohmann-json >> /etc/profile.d/z10_load_spack_modules.sh
RUN rm -fr /opt/spack/share/spack/modules/$linux-ubuntu22.04-x86_64_v3

RUN mkdir -p /opt/bcm && curl -sL https://github.com/boost-cmake/bcm/archive/refs/heads/master.tar.gz | tar -xz --strip-components 1 -C /opt/bcm \
 && cmake -B /tmp/build/bcm -S /opt/bcm && cmake --build /tmp/build/bcm --target install

RUN mkdir -p /opt/plog && curl -sL https://github.com/SergiusTheBest/plog/archive/refs/tags/1.1.10.tar.gz | tar -xz --strip-components 1 -C /opt/plog \
 && cmake -B /tmp/build/plog -S /opt/plog && cmake --build /tmp/build/plog --target install

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
ENV ESI_DIR=/esi
ENV HOME=$ESI_DIR
ENV OPTIX_DIR=/usr/local/optix
ENV OPTICKS_HOME=${ESI_DIR}/eic-opticks
ENV OPTICKS_PREFIX=/usr/local/eic-opticks
ENV OPTICKS_CUDA_PREFIX=/usr/local/cuda
ENV OPTICKS_OPTIX_PREFIX=${OPTIX_DIR}
ENV OPTICKS_COMPUTE_CAPABILITY=89
ENV LD_LIBRARY_PATH=${OPTICKS_PREFIX}/lib:${LD_LIBRARY_PATH}
ENV PATH=${OPTICKS_PREFIX}/bin:${OPTICKS_PREFIX}/lib:${PATH}
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility
ENV VIRTUAL_ENV_DISABLE_PROMPT=1
ENV TMP=/tmp
ENV CMAKE_PREFIX_PATH=${OPTICKS_PREFIX}

WORKDIR $ESI_DIR

COPY . .
COPY NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh .

RUN mkdir -p $OPTIX_DIR && ./NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh --skip-license --prefix=$OPTIX_DIR
RUN mkdir -p $OPTICKS_HOME && curl -sL https://github.com/BNLNPPS/eic-opticks/archive/da5bcc87.tar.gz | tar -xz --strip-components 1 -C $OPTICKS_HOME

RUN cmake -S $OPTICKS_HOME -B $OPTICKS_PREFIX/build -DCMAKE_INSTALL_PREFIX=$OPTICKS_PREFIX -DCMAKE_BUILD_TYPE=Debug \
 && cmake --build $OPTICKS_PREFIX/build --parallel --target install

RUN rm -fr $OPTIX_DIR/* $ESI_DIR/NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh

# Set up python environment with poetry
RUN mkdir -p /opt/pypoetry

ENV POETRY_CONFIG_DIR=/opt/pypoetry/config
ENV POETRY_VIRTUALENVS_PATH=/opt/pypoetry/venv
ENV POETRY_DATA_DIR=/opt/pypoetry/share
ENV POETRY_CACHE_DIR=/opt/pypoetry/cache

RUN poetry install
RUN poetry add $OPTICKS_HOME
RUN echo -e "source $(poetry env info --path)/bin/activate" >> /etc/profile.d/z20_poetry_env.sh
