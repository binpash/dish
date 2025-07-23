# Overview  
The paper makes the following claims requiring artifact evaluation on page 2 (Comments to AEC reviewers are after `:`):  

1. **Execution engine**:  FRACTAL's light-weight instrumentation, progress and health monitors, and the executor runtime work together to offer efficient and precise recovery.  
2. **Performance optimizations**: FRACTAL's critical-path components that reduces runtime overhead, including an *event-driven executor design*, *buffered-io sentinel striping*, and *batched scheduling*.  
3. **Fault injection**:  an internal subsystem, *frac*, that enables precise, large-scale characterization of fault recovery behaviors.  


This artifact targets the following badges (mirroring [the NSDI26 artifact "evaluation process"](https://www.usenix.org/conference/nsdi26/call-for-artifacts)):  

* [ ] [Artifact available](#artifact-available): Reviewers are expected to confirm public availability of core components (10 minutes)  
* [ ] [Artifact functional](#artifact-functional): Reviewers are expected to verify distributed execution workflow (30 minutes)  
* [ ] [Results reproducible](#results-reproducible): Reviewers are expected to reproduce key fault tolerance metrics (ZZ hours)  

**To "kick the tires" for this artifact:**
* Skim this README file to get an idea of the structure (2 minutes).
* Jump straight into the [Exercisability](#exercisability) section of the README file (10 minutes).

> [!IMPORTANT]
> We have reserved one 4-node cluster and one 30-node cluster on CloudLab **from August 1st to August 24th** for artifact evaluation.
> Reviewers should coordinate to not run experiments at the same time.
> We strongly encourage reviewers to begin the evaluation at least one week before the reservation period ends.
> If additional time is needed, please notify us as early as possible so we can arrange access to alternative resources.

<a id="artifact-available"></a>  
# Artifact Available (10 minutes)  
Confirm core components are publicly available.  

The implementation described in the NSDI26 paper (FRACTAL) has been incorporated into DiSh, MIT-licensed open-source software. It is part of the PaSh project, hosted by the [Linux Foundation](https://www.linuxfoundation.org/press/press-release/linux-foundation-to-host-the-pash-project-accelerating-shell-scripting-with-automated-parallelization-for-industrial-use-cases). Below are some relevant links:  

- FRACTAL is permanently hosted on the GitHub [binpash](https://github.com/binpash/) organization.  
- FRACTAL's command annotations conform to the format outlined in [PaSh](https://github.com/binpash/pash), a MIT-licensed open-source software.  
- We have a publicly-accessible discord Server ([Invite](http://join.binpa.sh/)) for troubleshooting and feedback.  
 
<a id="artifact-functional"></a>  
# Artifact Functional (30 minutes)  

Confirm sufficient documentation, key components as described in the paper, and execution with min inputs (about 30 minutes).  

## Documentation
Below is a map of all additional README files that explain specific subsystems.

* Top-level: [overall architecture](./README.md), [control-plane](./pash/compiler/dspash/README.md), [runtime](./runtime/README.md).
* Components: [remote pipes](./runtime/pipe/README.md), [DFS reader](./runtime/dfs/README.md), [runtime helpers](./runtime/scripts/README.md)(including builder, fault-injection mechanism).
* Setup and evaluation: [cluster boostrap](./docker-hadoop/README.md), [evaluation](./evaluation/README.md).
* Development: [contribution](./CONTRIBUTING.md). 

<!-- * **Top-level overview**: `README.md` (root)  
quick intro, install, architecture figure.
* **Control-plane internals**: `pash/compiler/dspash/README.md`: coordinator scheduler, executor event loop, dynamic persistence flow, and health/progress monitors (A1, A3–A6; §4–5)
* **Remote Pipe family**  
* `runtime/pipe/README.md`: high-level channel semantics  
* `runtime/pipe/datastream/README.md`: buffered-I/O implementation  
* `runtime/pipe/discovery/README.md`: endpoint registry / progress monitor
* **DFS split reader**: `runtime/dfs/README.md`: block-aligned HDFS reader used by executors for parallel ingestion (§4)
* **Executor helper scripts**: `runtime/scripts/README.md`: build helpers, fault-injection utilities, and cluster maintenance shell tools (§4, §6)
* **Runtime README (Go services)**: `runtime/README.md`: build & run instructions for Go daemons powering Remote Pipes, Discovery, and DFS (§4)
* **Cluster bootstrap**: `docker-hadoop/README.md`: Docker-Compose/Swarm recipes for spinning up a multi-node FRACTAL+HDFS cluster locally or on CloudLab (§7)
* **Benchmark & evaluation**: `evaluation/README.md`: scripts and guidance to reproduce functional, performance, and fault-tolerance experiments (§7) -->

<!-- For running the evaluation scripts refer to `evaluation/README.md`; for fault
injection see `runtime/scripts/README.md`.

For developer-focused instructions (e.g.
adding benchmark suites or rebuilding cluster workers) see
[CONTRIBUTING.md](CONTRIBUTING.md). -->

## Completeness
Fig. 3 of the paper gives an overview of the interaction among different components. Below we map every component to the source code in this repository.

- **Execution engine (§4)**
  - *DFG construction & fault-aware partitioning*: FRACTAL reuses the PaSh-JIT front-end to parse the user script and consult the JSON annotation corpus in `pash/annotations/`.  We then extend that pipeline in
    - `pash/compiler/dspash/ir_helper.py`: `prepare_graph_for_remote_exec`, `split_main_graph`, `add_singular_flags` (edge IDs, remote-pipe vertices, singular tagging, subgraph carving).  
    - `pash/compiler/dspash/worker_manager.py`: subgraph-to-node mapping, dependency tracking, selective re-execution.
  - *Remote pipe* & *Dynamic output persistence*: FRACTAL decides at run time, **per sub-graph**, whether to spill a stream to disk.  The choice is encoded via the `--ft dynamic` flag and a `-s` (singular) tag in each `RemotePipe`.  If dynamic FT is on and the subgraph is not singular, `datastream.go::writeOptimized()` writes to a spill-file whose path is registered in Discovery.  Upon a fault `worker_manager.check_persisted_discovery()` queries Discovery and re-executes only the subgraphs whose outputs were not already persisted.
  - *Executor runtime* & *Progress/Health monitors*: each node runs `pash/compiler/dspash/worker.py` where `EventLoop` launches up to *N* subgraphs and `TimeRecorder` logs execution.  Completion of every send/receive emits a 17-byte event (bottom of `datastream.go`) that `worker_manager.py::__manage_connection` consumes.  Cluster liveness comes from JMX polling in `pash/compiler/dspash/hdfs_utils.py` with callbacks wired into the scheduler.

- **Performance optimizations (§5)**
  - *Event-driven architecture*: `EventLoop` in `worker.py` is lock-free (list ops + atomics) and polls every 0.1 s, precisely the design described in §5.1.
  - *Buffered-IO sentinel stripping*: the 8-byte EOF token is removed on-the-fly inside `datastream.go::read` (≈ 70-130) using a single 4096-byte buffer, matching §5.2.
  - *Batched scheduling*: `worker_manager.py` builds `worker_to_batches` and issues one `Batch-Exec-Graph` RPC per worker, implementing the optimisation in §5.3.

- **Fault injection (§6)**
  - *frac subsystem*: the coordinator exposes `--kill` knobs handled in `worker_manager.py::handle_kill_node`; helpers in `runtime/scripts/killall.sh` terminate full process trees.  Evaluation scripts drive these hooks to reproduce the fault-tolerance experiments of §6.

Together these files (and the PaSh-JIT submodule they build upon) cover every component shown in Fig. 3, demonstrating that the released code fully realises the design presented in the paper.

## **Exercisability**

**Scripts and Data:** Scripts to run experiments are provided in the [./evaluation](./evaluation/) directory. To run all benchmarks, use [evaluation/run_all.sh](./evaluation/run_all.sh). To run a specific benchmark, use the `run.sh` script located within each benchmark folder (e.g., `evaluation/classics/run.sh`). The required input data for each benchmark can be downloaded using `inputs.sh`, which fetches datasets from persistent storage hosted on a Brown University cluster at https://atlas.cs.brown.edu/data.

**Execution:** To facilitate evaluation, we pre-allocate and initialize both the 4-node and 30-node clusters with all input data pre-downloaded. We have created a `fractal-ae26` account on the two CloudLab clusters used in our evaluation of Fractal. 

To connect to the control node of each cluster:

```bash
# Connect to the 4-node cluster
ssh -i ./evaluation/cloudlab.pem fractal-ae26@ms0813.utah.cloudlab.us
# Connect to the 30-node cluster
ssh -i ./evaluation/cloudlab.pem fractal-ae26@ms0809.utah.cloudlab.us
```

To start and connect to a client container:
```bash 
# Start the client container
sudo ./dish/docker-hadoop/start-client.sh --eval 
# Run the interactive shell inside the client continaer
docker exec -it docker-hadoop-client-1 bash
```

To run Fractal with a minimal `echo` example under a fault-free setting:
```bash
$DISH_TOP/pash/pa.sh --distributed_exec -c "echo Hello World!" 
```

<!-- ### Pre-requisites
1. Set up cloudlab account and have reserved a cluster (note: this will be done by the time ae is submitted)

🚧 YZ: Do we expect users to run the following setup commands in a specific env, e.g., provided docker image? If not, add commands to install dependencies, e.g., installing `clush` using `pip` on MacOS. 

### Set up cloudlab cluster swarm
1. Create a file at `docker-hadoop/manifest.xml` for pasting the cluster manifest from cloudlab
2. Run `cd docker-hadoop`
3. Run `./prepare-cloudlab-notes.sh manifest.xml [cloudlab-username]` (🚧 YZ: 14:08.12 mins)
4. Now all the hostnames in the cluster are in `hostnames.txt` with the first entry being the manager node.
5. Now ssh into that node with something like `ssh [username]@$(head -n 1 hostnames.txt)` (🚧 YZ: explicitly say the first ip in the hostnames.txt?)
6. Run `cd dish/docker-hadoop`
7. Run `sudo ./start-client.sh --eval` where client is `nodemanager`
8. Run `docker exec -it docker-hadoop-client-1 bash` to get inside the client node's container.

### Shutdown
1. Run `sudo docker compose -f docker-compose-client.yml down` to shutdown the client docker image
2. Run `./stop-swarm`
3. Run `docker swarm leave -force` -->

<!-- *(Developer note moved to CONTRIBUTING.md)* -->

<a id="results-reproducible"></a>  
# Results Reproducible (~ 5 hours)

The key results in this paper's evaluation section are the following:
1. *Fault-free execution*: FRACTAL also delivers near state-of-the-art performance in failure-free executions (§6.1, Fig.4).
2. *Fault recovery execution*: FRACTAL provides *correct* and *efficient* recovery for both regular node failure and merger node failure (§6.2, Fig.5, Fig.7).
<!-- 3. [Not urgent, nice to have] *Dynamic output persistence*: it demonstrates a subtle balance between accelerated fault recovery and overhead in fault-free execution (§6.3, Fig. 8). -->

**Terminology correspondence:** Here is the correspondence of flag names between the paper and the artifact:
* Fractal (no fault): `--width 8 --r_split --distributed_exec --ft dynamic`
* Fractal (regular-node fault): `--width 8 --r_split --distributed_exec --ft dynamic --kill regular`
* Fractal (merger-node fault):`--width 8 --r_split --distributed_exec --ft dynamic --kill merger`

**Execution and Plotting:** We provide two input load sizes for testing and evaluating Fractal:
- `--small`: Uses a reduced input size, resulting in shorter execution time (~X hours).  
- `--full`: Matches the input size used in the paper (~X hours).

The `--small` option produces results that closely match those presented in the paper. All key performance differences between configurations are still clearly observable.

This section also provide detailed instrauctions on how to replicate the figures of the experimental evaluation of Fractal as described in Table 2: [Classics](./evaluation/classics/), [Unix50](./evaluation/unix50/), [NLP](./evaluation/nlp/), [Analytics](./evaluation/analytics/), and [Automation](./evaluation/automation/).

To run all the benchmarks with `--small` input from the control node **for each cluster**

```bash
# open the interactive shell for the client container
docker exec -it docker-hadoop-client-1 bash

# enter the eval folder
cd $DISH_TOP/evaluation

# There are two options here, either use --small or --full as an argument to determine the input size.
bash run_all.sh --small
```

Generating the plots requires data from both clusters. To parse the per-cluster results, run the following command with `--site 4` for the 4-node cluster or `--site 30` for the 30-node cluster:

```bash
# Parse results for 4-node cluster
./plotting/scripts/parse.sh --site 4
# For 30-node cluster
./plotting/scripts/parse.sh --site 30
```

After parsing results from both clusters, run the following command on any control node to generate the final figures by aggregating the results:

```bash
# Generate the plots
./plotting/scripts/plot.sh ms0813.utah.cloudlab.us ms0809.utah.cloudlab.us
```

Once the script completes, follow its prompt to open the following URLs in a browser to view the generated figures, for example:
```
Fig. 4: http://ms0813.utah.cloudlab.us/fig4.pdf  
Fig. 5: http://ms0813.utah.cloudlab.us/fig5.pdf  
Fig. 7: http://ms0813.utah.cloudlab.us/fig7.pdf
```

<!-- We have included in this repo sample data of the raw data timers (run.tmp), the final source data (data_final.csv) and the three output figures: [Fig. X](), [Fig. Y](), and [Fig. Z]() -->

<!-- > After benchmarks complete, rebuild plotting datasets and figures:
> ```bash 
# Merge raw_times_site*.csv first if you collected results on both clusters
> evaluation/plotting/scripts/merge_sites.sh \
>     evaluation/results/raw_times_site4.csv evaluation/results/raw_times_site30.csv
>
> # Pre-process into the three figure datasets
> python evaluation/plotting/scripts/preprocess.py
>
> # Generate PDFs (figures/<timestamp>/)
> python evaluation/plotting/scripts/plot.py
> ```
>
> If you ran inside Docker on a remote VM, copy the PDFs out:
> ```bash
> docker cp docker-hadoop-client-1:/opt/dish/evaluation/plotting/figures ./plots
> scp -i <pem> user@<vm-host>:~/plots/*.pdf ./local_plots/
> ``` -->

## [Optional] Hard faults (~1 week of manual effort)
Optionally, you may try to introduce *hard faults*. However, despite its conceptual simplicity, introducing and monitoring *hard faults* requires significant time and effort. 

As shown at the bottom of page 10, replicating the presented hard faults experiment involves `3 completion percents × 3 system configs (AHS, regular ,
merger ) × 2 failure modes × 5 repetitions × 3 benchmarks = 270 experiments`, which took about a week of manual effort.

The procedures are listed below (let's set the experiment config for classics/top-n.sh, fault at 50%, merger fault):

1. Prerequisites: set up a cloud deployment for Fractal
2. Follow the [Exercisability](#exercisability) section of the instruction file to enter the interactive shell for the client node
2. Set up benchmark input: `cd $DISH_TOP/evaluation/classics; ./inputs.sh`
3. To simplify the experiment, comment out all lines from L23-32 except for L25 in run.sh file to run only top-n
3. Run the fault-free execution to record the fault-free time: `./run.sh`
4. Collect the ip address for all other remote nodes' datanode container. One simple way is to do `hostname -i`
5. When the fault-free run is complete, run `./run.sh` again and *start a timer on the side*
6. During scheduling the worker-manager stores the IP of the machine that will run the merger sub-graph in a small helper file. `cat $PASH_TOP/compiler/dspash/hard_kill_ip_path.log` contains two lines:
- Line 1 -> IP (or hostname) of the merger node.
- Line 2 -> IP of one regular (non-merger) nod
7. Now when the timer has reached 0.5*{fault-free time}, shutdown the remote node corresponding to the merger node's ip. If you are using a cloudlab deployment, one way to do so is through cloudlab's web console for the corresponding log. Click the corresponding GUI and select the "terminate" option for non-graceful shutdown
8. When Fractal detects, recovers, and eventually completes this run (in the client's container), reboot the just-shutdown node, and wait until it's back up
9. To make sure it is back and stable, we need to check whether all of its data blocks are back online (i.e., whether replication factor is satisfied)


