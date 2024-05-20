# Mass-Transport System Analytics

This set of scripts script is part of [a recent study on OASA](https://insidestory.gr/article/noymera-leoforeia-athinas) from Diomidis Spinellis and Eleftheria Tsaliki.  OASA is the the mass-transport system supporting the city of Athens. 

1. `1.sh`: Vehicles on the road per day
2. `2.sh`: Days a vehicle is on the road
3. `3.sh`: Hours each vehicle is on the road
4. `4.sh`: Hours monitored each day
5. `5.sh`: Hours each bus is active each day

## Downloading Inputs

Run `./input.sh`. Default book count will download a zipped csv file (3.4G after unzipping). Use the `--small` flag to download a small one (7.7MB after unzipping).

## Running covid-mts

Run `./run.sh` to run all scripts. Use `--small` flag to run with the small input
5.sh doesn't work, as noted in PaSh OSDI paper (which describes covid-mts as a suite with 4 scripts).

## Verify covid-mts

Run `./verify.sh` to compare output hashes to the bash output hashes
Each script reads the following environment variables:

- `--generate`: generate the hash
- `--small --generate`: generate the hash for small input