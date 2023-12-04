### How does docker cache work?

Each command in docker is cached. For example if you have `RUN sudo apt update && sudo apt upgrade` in your dockerfile, only the first time you build your image the packages will be downloaded. Later builds will be using the cache even if there is an update in one of your packages.

Another example is `RUN git clone some-repo`. Your repository will be cloned the first time you build and even if you push something later on, you will see the older commit in your docker due to the cache.

One way to prevent this is to build with `--no-cache` flag. But this means you need to add this flag everywhere you build an image. Another option is to clear the cache when needed `docker builder prune`. However both of these suffer from the fact that without the cache, our builds takes too long.

To overcome this, we can use `ADD` or `COPY`. Both of these invalides the cache if the source has any change. For example using `COPY some-repo /opt/some-repo` will invalidate the cache and rebuild the layer if any file inside `some-repo` changes. Furthermore this won't require to push your changes just to build the image.

One important thing to note here is, layer invalidation will invalidate all layers after that layer.

### How do we build dish?

We have 2 entry points: `docker-hadoop/setup-compose.sh` and `docker-hadoop/swarm-compose.sh`. The difference is that swarm uses different nodes for different images, while compose use same node for all of them. From this point on I will specificly talk about compose as they are similar.

When we run `docker-hadoop/setup-compose.sh`. This script builds all the images with the help of `docker-hadoop/Makefile`. There are different images but the most important ones are `pash-base` (`docker-hadoop/pash-base`) and `hadoop-pash-base`(`docker-hadoop/base`). All of the other images are `FROM hadoop-pash-base`. Actually we could merge these 2 base images into one probably. My guess is they are separate because `pash-base` was copied from somehwere else initally.

Once all of the images are build, we run those images with the help of the docker compose. This means you can shut them down with `docker compose down` and indeed thats what `docker-hadoop/stop-compose.sh` does.

### How can we shoren build time (4m -> 3s)?

Now that we know how cache work and how we build, let's take a look what takes long if we were to use `COPY some-repo /opt/some-repo`. Once we investiage what takes a long time, we can see that downloading dependencies takes most of the time.

This suggets that we should move copying after installing dependenices. However there is a problem with this idea because we install dependencies using a script inside the repo. This means that we should have the repo inside the image before we install the dependenices but if we do, for every change (even a readme change) will require downlading all dependencies again.

One solution we can come up with to separate dependencies from the other files. This would make sense if our dependencies were to be a list in a file. But instead they are couple of shell scripts that depend on multiple other shell scripts and the directory hierarchy.

So what I did is to keep `RUN git clone some-repo` at the beginning and later on I override this with `COPY some-repo /opt/some-repo`. This way we initially get a cached layer to download the dependencies, then use cached dependencies and then lastly copy the updated repository. This way I was able to reduce local image build time from 4 minute to 3 second for subsequent builds.

This means if you were to update the dependencies, you must clear the cache before rebuilding.

### Note about -v flag for docker compose down

When you add something to hdfs, those files are stored in the real disks mapped into the docker (volumes). So when you shut down the system etither via `docker compose down` or `docker-hadoop/stop-compose.sh`, you will keep hdfs state next time you start your system. This could be something useful but if not, you could clear these volumes by passing `-v` flag to either command like `docker compose down -v` or `docker-hadoop/stop-compose.sh -v`.
