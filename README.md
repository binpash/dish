# DiSh: Dynamic Shell-Script Distribution 

> _A system for scaling out POSIX shell scripts on distributed file systems._
> _Hosted by the [Linux Foundation](https://linuxfoundation.org/press-release/linux-foundation-to-host-the-pash-project-accelerating-shell-scripting-with-automated-parallelization-for-industrial-use-cases/)._

DiSh builds heavily on and extends [PaSh](https://github.com/binpash/pash) (command annotations, compiler infrastructure, and JIT orchestration).

Quick Jump: [Installation](#installation) | [Running DiSh](#running-dish) | [Repo Structure](#repo-structure) | [Evaluation](#evaluation) | [Community & More](#community--more) | [Citing](#citing)

## Installation

The easiest way to install dish and play with it is using docker.

See https://docs.docker.com/engine/install/ for the docker installation steps if you don't have it already.

The following steps commands will create a virtual cluster on one machine allow you to play with DiSh. If you have multiple machines, you can setup [docker-swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/) and run the `./setup-swarm.sh` command instead of `./setup-client.sh`

```sh
cd docker-hadoop
./setup-compose.sh # Creates the virtual cluster on the host machine
./start-client.sh # Creates a client
docker exec -it docker-hadoop_client_1 bash # ssh into the client
```

## Running DiSh

__TODO:__ Describe how to run a hello world script. See PaSh's README for inspiration.

## Repo Structure

This repo hosts most of the components of the `dish` development. Some of them are incorporated in [PaSh](https://github.com/binpash/pash) The structure is as follows:

* [pash](./pash): Contains the complete PaSh repo as a submodule. DiSh uses and extends its annotations, compiler, and JIT orchestration infrastructure.
* [evaluation](./evaluation): Shell scripts used for evaluation.
* [runtime](./runtime): Runtime component — e.g., remote fifo channels.
* [scripts](./scripts): Scripts related to installation, deployment, and continuous integration.

## Evaluation

__TODO:__ Describe how to run DiSh's evaluation (also setting up a cluster etc).

## Community & More

Chat:
* [Discord Server](ttps://discord.com/channels/947328962739187753/) ([Invite](http://join.binpa.sh/))

Mailing Lists:
* [pash-devs](https://groups.google.com/g/pash-devs): Join this mailing list for discussing all things `pash`
* [pash-commits](https://groups.google.com/g/pash-commits): Join this mailing list for commit notifications

Development/contributions:
* Contribution guide: [docs/contributing](docs/contributing/contrib.md)
* Continuous Integration Server: [ci.binpa.sh](http://ci.binpa.sh)

## Citing

__TODO__

If you used DiSh, consider citing the following paper:
```
@inproceedings{dish2023nsdi,
author = {Mustafa, Tammam and Kallas, Konstantinos and Das, Pratyush and Vasilakis, Nikos},
title = {DiSh: Dynamic Shell-Script Distribution},
year = {2023},
}
```
