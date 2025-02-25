## esi-shell

This repository provides a containerized environment designed for reproducible
simulation jobs. It leverages the Geant4 simulation framework and NVIDIA OptiX
ray-tracing capabilities, offering a streamlined setup for a GPU-accelerated
environment, whether used interactively or non-interactively.


### Prerequisites

Before starting, make sure you have the following prerequisites available and
installed:

* A CUDA-capable NVIDIA GPU
* [Docker Engine](https://docs.docker.com/engine/install/)
* NVIDIA container toolkit ([installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))


### Quick start

The installer script for the `esi-shell` container is available directly at
[bnlnpps.github.io/esi-shell/](https://bnlnpps.github.io/esi-shell/esi-shell).
It can be downloaded and then made executable:

```shell
curl -Os https://bnlnpps.github.io/esi-shell/esi-shell && chmod u+x esi-shell
```

The `esi-shell` environment can be used interactively by running the script:

```shell
./esi-shell
```

Once the container is up, you can execute the code relying on GPU functionality,
e.g. run the available tests:

```shell
eic-opticks/tests/test_opticks.sh
```

It is also possible to run any container command non-interactively:

```shell
./esi-shell eic-opticks/tests/test_opticks.sh
```

Use the `-h/--help` option to get a quick summary of available options and to
learn how to pass arguments to the underlying container, e.g.:

```shell
./esi-shell --help
./esi-shell -- -v $HOME/out:/tmp/results
```


### For developers

If you plan to develop the code utilizing ray-tracing GPU capabilities, you will
likely need to install [NVIDIA
OptiX](https://developer.nvidia.com/designworks/optix/download). After
downloading the appropriate SDK version, install it on your host system. We
recommend installing OptiX in `/usr/local/optix` but any other path will be as
good:

```
export OPTIX_DIR=$HOME/optix
mkdir -p $OPTIX_DIR
./NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh --prefix=$OPTIX_DIR
```

When running `esi-shell`, make sure that the environment variable `OPTIX_DIR` is
configured to point to the directory where OptiX is installed. If not set, the
default path `OPTIX_DIR=/usr/local/optix` will be mounted inside the container
at runtime.

Once the above step is performed, the developer can bind-mount any directory
with the source code in the interactive shell:

```
esi-shell -- -e HOME=$HOME -w $HOME
```


#### Building a local image

Another option to make OptiX available for development inside your local
container is to rebuild the image using the `Dockerfile` in the `esi-shell`
repository. Place the downloaded NVIDIA OptiX installation file on the same path
where you cloned
[github.com/BNLNPPS/esi-shell](https://github.com/BNLNPPS/esi-shell):

```shell
cd esi-shell
ls
... NVIDIA-OptiX-SDK-7.6.0-linux64-x86_64.sh ...
```

This self-unpacking shell file will be used to install OptiX inside the
`esi-shell` image built locally:

```shell
docker build -t esi-shell .
```


#### Using `esi-shell` Docker Images

The `esi-shell` script simplifies the setup of a GPU-enabled Geant4 simulation
environment. However, if you prefer, you can work directly with the [`esi-shell`
Docker images](https://github.com/BNLNPPS/esi-shell/pkgs/container/esi-shell).
These images can be pulled from the registry and used independently of the
script, providing additional flexibility for various use cases.

To run a tagged image with your local NVIDIA OptiX installation, use the
following command:

```shell
docker run --rm -it --gpus all -v /usr/local/optix:$OPTIX_DIR ghcr.io/bnlnpps/esi-shell:<tag>
```

This command is equivalent to using the shorter `esi-shell` command:

```shell
esi-shell -t <tag>
```

A complete list of available tagged releases can be found
[here](https://github.com/BNLNPPS/esi-shell/pkgs/container/esi-shell).

To run the container on a remote host (`HOST`), set the `DOCKER_HOST`
environment variable. For example, if you have SSH access to a GPU-capable host,
prepend your `docker` or `esi-shell` commands with `DOCKER_HOST`:

```shell
DOCKER_HOST=ssh://HOST docker run ghcr.io/bnlnpps/esi-shell
DOCKER_HOST=ssh://HOST esi-shell
```

To enable X11 forwarding, pass your local `DISPLAY` and `HOME` environment
variables to the container:

```shell
docker run -e DISPLAY=$DISPLAY -v $HOME/.Xauthority:/esi/.Xauthority --net=host ghcr.io/bnlnpps/esi-shell
```

These arguments can also be passed to `esi-shell` after the `--` option divider.
When running the container on a remote host, use the environment variables
defined on that host:

```shell
DOCKER_HOST=ssh://HOST esi-shell -- -e DISPLAY=$(ssh HOST 'echo $DISPLAY') -v $(ssh HOST 'echo $HOME')/.Xauthority:/esi/.Xauthority --net=host
```
