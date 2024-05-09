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

* Create a personal access token with privilege to download packages from github package registry
<img width="992" alt="Screenshot 2024-05-07 at 9 36 36 PM" src="https://github.com/BNLNPPS/esi-shell/assets/7409132/c58477d6-80a9-4a57-855a-20f755c9a0c8">

* Login to github package registry with your token.
  
  ```shell
    export TOKEN=<YOUR_TOKEN>
    echo $TOKEN | docker login ghcr.io -u USERNAME --password-stdin
  ```
* Pull the tagged release you want to run from the registry. For example:
  
  ```shell
   docker pull ghcr.io/bnlnpps/esi-shell:latest
  ```
  The list of all tagged releases can be found [here](https://github.com/BNLNPPS/esi-shell/pkgs/container/esi-shell).
  
* Run the tagged release with the local nvidia optix installation

  ```shell
    docker run --rm -it --gpus all -v /usr/local/optix:/usr/local/optix -e HOME=/esi-shell ghcr.io/bnlnpps/esi-shell:latest
  ```

  Explanation of the docker command:
  ```
  docker run: Instructs Docker to run a container.
  --rm: Ensures that the container is removed after it stops running.
  -it:  Make the container interactive.
  --gpus all: Specifies that all available GPUs should be accessible within the container.
  -v /usr/local/optix:/usr/local/optix: Mounts the host directory /usr/local/optix into the container at the same location.
  -e HOME=/esi-shell: Sets the environment variable HOME to /esi-shell within the container.
  ghcr.io/bnlnpps/esi-shell:1.0.0-beta.4: Image and tag in github package registry. 
  ```
* Build the code and run unit tests

  ```shell
    opticks-full
    opticks-t
  ```

---

Convert gdml geometry to CSG

```
opticks/g4cx/tests/G4CXOpticks_setGeometry_Test.sh
```
