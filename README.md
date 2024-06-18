## esi-shell

The goal of this project is to provide a stable containerized environment for reproducible
simulation jobs levereging on the Geant4 and NVIDIA OptiX ray tracing capabilities.

### Prerequisites

Before starting, make sure you have the following prerequisites available and installed:

* A CUDA-capable NVIDIA GPU
* [Docker Engine](https://docs.docker.com/engine/install/)
* NVIDIA container toolkit ([installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))


### Quick start

The installer script for the `esi-shell` container is available directly at
[bnlnpps.github.io/esi-shell/](https://bnlnpps.github.io/esi-shell/esi-shell). It can be downloaded
and then made executable:

```shell
curl -Os https://bnlnpps.github.io/esi-shell/esi-shell && chmod u+x esi-shell
```

The `esi-shell` environment can be used interactively by running the script:

```shell
./esi-shell
```

Once the container is up, you can execute the code relying on GPU functionality, e.g. run the
available tests:

```shell
opticks-full-prepare
opticks-t
```

It is also possible to run any container command non-interactively:

```shell
./esi-shell "opticks-full-prepare && opticks-t"
```

Use the `-h/--help` option to get a quick summary of available options and to learn how to pass
arguments to the underlying container, e.g.:

```shell
./esi-shell --help
./esi-shell -- -v $HOME/out:/tmp/results
```


### For developers

If you plan to develop the code utilizing GPU capabilities, you will likely need to install [NVIDIA
OptiX](https://developer.nvidia.com/designworks/optix/download). Place the downloaded file on the
same path where you cloned [github.com/BNLNPPS/esi-shell](https://github.com/BNLNPPS/esi-shell):

```shell
cd esi-shell
ls
... NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh ...
```

Now, the `esi-shell` image can be built locally

```shell
docker build -t esi-shell .
```

For local development with OptiX, install it on your host system. We recommend installing OptiX in
`/usr/local/optix` but any other path will be as good:

```
export OPTIX_DIR=$HOME/optix
mkdir -p $OPTIX_DIR
./NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh --prefix=$OPTIX_DIR
```

When running `esi-shell`, make sure that the environment variable `OPTIX_DIR` is configured to point
to the directory where OptiX is installed. If not set, the default path `OPTIX_DIR=/usr/local/optix`
will be mounted insdie the container at runtime.


#### Docker

If preferred, you can pull a tagged release from the registry and work with the images directly. The
list of all tagged releases can be found
[here](https://github.com/BNLNPPS/esi-shell/pkgs/container/esi-shell). Run the tagged image with
the local NVIDIA OptiX installation, e.g.:

```shell
docker run --rm -it --gpus all -v /usr/local/optix:$OPTIX_DIR ghcr.io/bnlnpps/esi-shell:<tag>
```
