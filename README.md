# DiSh: Dynamic Shell-Script Distribution 

> _A system for scaling out POSIX shell scripts on distributed file systems._
> _Part of the PaSh project, which is hosted by the [Linux Foundation](https://linuxfoundation.org/press-release/linux-foundation-to-host-the-pash-project-accelerating-shell-scripting-with-automated-parallelization-for-industrial-use-cases/)._

DiSh builds heavily on and extends [PaSh](https://github.com/binpash/pash) (command annotations, compiler infrastructure, and JIT orchestration).

Quick Jump: [Installation](#installation) | [Running DiSh](#running-dish) | [Repo Structure](#repo-structure) | [Evaluation](#evaluation) | [Community & More](#community--more) | [Citing](#citing)

## Installation

The easiest way to play with DiSh is using docker.

The following steps commands will create a virtual cluster on one machine allow you to experiment with DiSh. If you have multiple machines, you can setup [docker-swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/) and use the swarm instruction in [docker-hadoop](./docker-hadoop).

```sh
## Clone the repo
git clone --recurse-submodules https://github.com/binpash/dish.git

## Install docker using our script (tested on Ubuntu)
## Alternatively see https://docs.docker.com/engine/install/ to install docker.
cd dish
./scripts/setup-docker.sh

cd docker-hadoop
## Create the virtual cluster on the host machine
./setup-compose.sh # currently takes several minutes due to rebuilding the images
## The cluster can be torn down using `docker compose down`

## Create a shell on the client
docker exec -it nodemanager1 bash
```

## Running DiSh

Let's run a very simple example using DiSh:

```sh
cd $DISH_TOP
hdfs dfs -put README.md /README.md # Copies the readme to hdfs
```

Now, you can run [this sample script](./scripts/sample.sh) (or create a script of your own). Run both DiSh and Bash and compare the results!

```
./di.sh sample.sh
bash sample.sh
```

<!-- We first want to download some input data and populate hdfs.

```sh
cd $DISH_TOP
./setup.sh # Takes several minutes
``` -->


## Repo Structure

This repo hosts most of the components of the `dish` development. Some of them are incorporated in [PaSh](https://github.com/binpash/pash) The structure is as follows:

* [pash](./pash): Contains the complete PaSh repo as a submodule. DiSh uses and extends its annotations, compiler, and JIT orchestration infrastructure.
* [evaluation](./evaluation): Shell scripts used for evaluation.
* [runtime](./runtime): Runtime component — e.g., remote fifo channels.
* [scripts](./scripts): Scripts related to installation, deployment, and continuous integration.

<!-- ## Evaluation -->

<!-- __TODO:__ Describe how to run DiSh's evaluation (also setting up a cluster etc). -->

## Community & More

Chat:
* [Discord Server](ttps://discord.com/channels/947328962739187753/) ([Invite](http://join.binpa.sh/))

## Citing

If you used DiSh, consider citing the following paper:
```
@inproceedings{dish2023nsdi,
author = {Mustafa, Tammam and Kallas, Konstantinos and Das, Pratyush and Vasilakis, Nikos},
title = {{DiSh}: Dynamic {Shell-Script} Distribution},
booktitle = {20th USENIX Symposium on Networked Systems Design and Implementation (NSDI 23)},
year = {2023},
isbn = {978-1-939133-33-5},
address = {Boston, MA},
pages = {341--356},
url = {https://www.usenix.org/conference/nsdi23/presentation/mustafa},
publisher = {USENIX Association},
month = apr,
}
```
