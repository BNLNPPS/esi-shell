# syntax=docker/dockerfile:latest

FROM ghcr.io/bnlnpps/esi-shell:1.4.4

ARG DEBIAN_FRONTEND=noninteractive
ARG WITH_TF=0          # set to 1 to install TensorFlow (CPU)
SHELL ["/bin/bash", "-lc"]

# --- System packages (includes requested Ubuntu Qt5) ---
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
    binutils cmake dpkg-dev g++ gcc git libssl-dev \
    libgsl-dev libxpm-dev libxft-dev libtbb-dev \
    libx11-dev libxext-dev libgif-dev python3 python3-dev \
    libgl1-mesa-dev libglu1-mesa-dev environment-modules \
    qtbase5-dev qtbase5-dev-tools qt5-qmake \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# --- Ensure ROOT and Geant4(+qt) are present via Spack (idempotent) ---
RUN spack install root && spack clean -a
RUN spack install geant4@11.1.2+qt && spack clean -a

# Ensure vdt is available (ROOT usually depends on it, but make explicit)
RUN spack install vdt && spack clean -a

# --- Prepare Spack modules; emit full dependency loads (includes vdt, etc.) ---
RUN spack module tcl refresh -y \
 && rm -rf /opt/modules \
 && cp -r /opt/spack/share/spack/modules/linux-ubuntu22.04-x86_64_v3 /opt/modules \
 && echo "module use --append /opt/modules" > /etc/profile.d/z10_load_spack_modules.sh \
 && { \
      spack module tcl loads --dependencies root; \
      spack module tcl loads --dependencies geant4@11.1.2+qt; \
    } >> /etc/profile.d/z10_load_spack_modules.sh

# --- Optional: TensorFlow (CPU) for CMake detection (off by default) ---
# This installs the TensorFlow C API + python wheel, and exports CMake hints.
RUN if [ "$WITH_TF" -eq 1 ]; then \
      set -euxo pipefail; \
      TF_VER=2.17.0; \
      curl -fsSL -o /tmp/libtensorflow.tgz \
        "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-${TF_VER}.tar.gz"; \
      tar -C /usr/local -xzf /tmp/libtensorflow.tgz; \
      rm /tmp/libtensorflow.tgz; \
      ldconfig; \
      python3 -m pip install --no-cache-dir --upgrade pip; \
      python3 -m pip install --no-cache-dir "tensorflow-cpu==${TF_VER}"; \
      printf '%s\n' \
        'export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}' \
        'export Tensorflow_INCLUDE_DIR=/usr/local/include' \
        'export Tensorflow_LIBRARY=/usr/local/lib/libtensorflow.so' \
        > /etc/profile.d/z40_tensorflow.sh; \
    fi

# --- Fetch and build ONLY RAT-PAC (reuse Spack's ROOT/G4/Qt) ---
RUN source /etc/profile.d/z10_load_spack_modules.sh \
 && git clone https://github.com/rat-pac/ratpac-setup.git /opt/ratpac-setup \
 && cd /opt/ratpac-setup \
 && ./setup.sh --only ratpac -j"$(nproc)"

# Make RAT-PAC available in every shell
ENV RATPAC_HOME=/opt/ratpac-setup
RUN printf 'source /opt/ratpac-setup/env.sh\n' > /etc/profile.d/z30_ratpac.sh \
 && if [ -x /opt/ratpac-setup/local/bin/rat ]; then ln -sf /opt/ratpac-setup/local/bin/rat /usr/local/bin/rat; fi \
 && if [ -x /opt/ratpac-setup/ratpac/build/bin/rat ]; then ln -sf /opt/ratpac-setup/ratpac/build/bin/rat /usr/local/bin/rat; fi

# (Optional) quick sanity check (remove if you want faster builds)
RUN source /etc/profile.d/z10_load_spack_modules.sh \
 && source /opt/ratpac-setup/env.sh \
 && rat -h >/dev/null 2>&1 || true

WORKDIR /esi
