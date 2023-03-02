# DiSh: Dynamic Shell-Script Distribution 

> _A system for scaling out POSIX shell scripts on distributed file systems._
> _Hosted by the [Linux Foundation](https://linuxfoundation.org/press-release/linux-foundation-to-host-the-pash-project-accelerating-shell-scripting-with-automated-parallelization-for-industrial-use-cases/)._

DiSh builds heavily on and extends [PaSh](https://github.com/binpash/pash) (command annotations, compiler infrastructure, and JIT orchestration).

Quick Jump: [Installation](#installation) | [Running DiSh](#running-dish) | [Repo Structure](#repo-structure) | [Evaluation](#evaluation) | [Community & More](#community--more) | [Citing](#citing)

## Installation

On Ubuntu, Fedora, and Debian run `./scripts/setup-dish.sh` to build DiSh and its dependencies.

__TODO:__ Is that enough? If there is anything else we should add it.


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
