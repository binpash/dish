NLP 

> Natural-language processing out of UNIX and Linux utilities

## Downloading Inputs

Run `./input.sh`. Default book count will be 120. Use the `--small` flag to download 10 books from Project Gutenberg. Use the `--full` flag to download 1000 books from Project Gutenberg.

## Running NLP

Run `./run.sh` to run all scripts.
Each script reads the following environment variables:

- `IN`: Where to find downloaded texts
- `ENTRIES`: Number of books to process 
