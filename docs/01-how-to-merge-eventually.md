### How did this (ft) branch is created?

Psuedoscript:
```
# clean clone from specific branches
mkdir tmp && cd tmp
git clone dish from main
git clone pash --with-submodules from ft-future
git clone docker-hadoop from main

# remove submodules in git
cd dish
git rm pash && git rm docker-hadoop

# remove git related files from directories to be copied
cd ../pash && rm -rf .git*
cd compiler/parser/libdash && rm -rf .git*
cd ../../../../docker-hadoop && rm -rf .git*

# copy directories
cd ..
cp -r pash dish/pash
cp -r docker-hadoop dish/docker-hadoop
```

### How are the updates in this (ft) branch will be eventually relayed into pash repo?

Psuedoscript:
```
# clean clone from specific branches
mkdir tmp && cd tmp
git clone dish from ft
git clone pash --with-submodules from ft-future

# remove everything except git files
cd pash
rm -rf -not .git*

# copy and commit updated files
cd ..
cp dish/pash/* pash
git commit -m "Add all work from fault tolerance"

# Merge and resolve
# This is where we were before this new branch
git merge main
```

If we want to re-split docker-hadoop, the process will be similar.
