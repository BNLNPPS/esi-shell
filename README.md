### Prerequisites

Before starting, make sure you have the following prerequisites installed:

* NVIDIA GPU supported by OptiX
* NVIDIA OptiX ([download](https://developer.nvidia.com/designworks/optix/download))
* NVIDIA container toolkit ([installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))

### esi-shell

Ensure that the environment variable `OPTIX_DIR` is configured to point to the directory where OptiX is installed, e.g.

```shell
export OPTIX_DIR=/usr/local/optix
```

Next, install and run `esi-shell`:

```shell
curl -Os https://bnlnpps.github.io/esi-opticks/esi-shell && chmod u+x esi-shell
./esi-shell
```

Once the container is up, you can build the code relying on GPU functionality and run the opticks tests:

```shell
opticks-full
opticks-t
```

### Docker

Here are basic instructions on how to build and run the `esi-opticks` container using Docker:

```shell
cd esi-opticks/
docker build -t bnlnpps/esi-opticks .
docker run --rm -it bnlnpps/esi-opticks
```

---

Convert gdml geometry to CSG

```
opticks/g4cx/tests/G4CXOpticks_setGeometry_Test.sh
```
