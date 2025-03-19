from spack.package import *


class EicOpticks(CMakePackage, CudaPackage):
    """EIC Opticks package for GPU simulation"""

    homepage = "https://github.com/bnlnpps/eic-opticks"
    url      = "https://github.com/bnlnpps/eic-opticks/archive/tags/1.0.0-rc1.tar.gz"
    git      = "https://github.com/bnlnpps/eic-opticks.git"

    maintainers = ["plexoos"]

    version("esi", branch="esi")
    version("1.0.0-rc1", sha256="bc503d9c3be15a326fc3004f601a023fd7383e5245c856fc715370d1cfff3620")

    depends_on("cmake@3.10:", type="build")
    depends_on("geant4")
    depends_on("glew")
    depends_on("glfw")
    depends_on("glm")
    depends_on("glu")
    depends_on("nlohmann-json")
    depends_on("plog")

    # External resource (e.g., an additional dataset, model, or patch file)
    resource(
        name="OptiX",
        url="https://developer.download.nvidia.com/redist/optix/v8.0/OptiX-8.0-Include.zip",
        sha256="ba617fbb61587bac99106dbd6cda5a27c9d178308cc423878ed72b220b8b951c",
        destination="resources",
        placement="optix/include"
    )

    def setup_build_environment(self, env):
        # Set an additional environment variable
        resource_path = self.stage.source_path + "/resources/optix"
        env.set('OPTICKS_OPTIX_PREFIX', resource_path)

    def cmake_args(self):
        args = []
        # Pass the resource path to CMake
        #resource_path = self.stage.source_path + "/resources/optix"
        #args.append("-DOptiX_INSTALL_DIR={0}".format(resource_path))
        #args.append("-DOPTICKS_OPTIX_PREFIX={0}".format(resource_path))
        args.append("-DCMAKE_BUILD_TYPE=Debug")
        return args
