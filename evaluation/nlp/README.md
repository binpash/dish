NLP 

> Natural-language processing out of UNIX and Linux utilities

## Downloading Inputs

Run `./input.sh`. Default book count will be 120. Use the `--small` flag to download 10 books from Project Gutenberg. Use the `--full` flag to download 1000 books from Project Gutenberg.

## Running NLP

Run `./run.sh` to run all scripts. Use `--small` flag to run with the small input

## Verify NLP

Run `./verify.sh` to compare output hashes to the bash output hashes
Each script reads the following environment variables:

- `--generate`: generate the hash
- `--small --generate`: generate the hash for small input