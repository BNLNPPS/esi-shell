# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class Opticks(CMakePackage, CudaPackage):
    """Opticks package for GPU simulation"""

    homepage = "https://github.com/bnlnpps/eic-opticks"
    git      = "https://github.com/bnlnpps/eic-opticks.git"

    maintainers("plexoos")

    version("main", branch="main")

    depends_on("cxx", type="build")
    depends_on("cmake@3.10:", type="build")
    depends_on("geant4@11.1:")
    depends_on("glew")
    depends_on("glfw")
    depends_on("glm")
    depends_on("glu")
    depends_on("nlohmann-json")
    depends_on("mesa ~llvm")
    depends_on("optix_dev@7:")
    depends_on("openssl")
    depends_on("plog")
