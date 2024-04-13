## Expert One-liners

This directory contains ten scripts collected by several sources, including GitHub, Stackoverflow, and the Unix literature.
They are written by developers who are (or approximate) experts in Unix shell scripting, and include several Unix classics.

1. `nfa-regex.sh`          Match complex regular-expression over input
2. `sort.sh`               Sort a text input
3. `top-n.sh`              Find the top 1000 terms in a document
4. `wf.sh`                 Calculate the frequency of each word in the document, and sort by frequency
5. `spell.sh`              Compute mispelled words in an input document
6. `bi-grams.sh`           Find all 2-grams in a piece of text
7. `diff.sh`               Compares two streams element by element
8. `set-diff.sh`           Show the set-difference between two streams (i.e., elements in the first that are not in the second).
9. `shortest-scripts.sh`   Find the shortest scripts 
10.`sort-sort.sh`          Calculate sort twice

The `bi-grams.aux.sh` script contains helper functions for `bi-grams.sh`. 
To generate inputs, run `./generate_inputs`.


## run.distr.ft.sh Usage
```sh
cd $DISH_TOP/evaluation/distr_benchmarks/oneliners
./run.distr.ft.sh [bash][hadoop-streaming][pash][dish][naive][base][optimized][clean][correctness][sanity]
```
| argument | function |
| ------ | ------ |
| sanity | This checks if dish has the same output as bash. Once we run this, we can use dish output as baseline. |
| bash | For each script in the suite, use bash to run it |
| hadoop-streaming | For each script in the suite, use HS to run it |
| pash | For each script in the suite, use pash to run it |
| dish | For each script in the suite, use dish to run it |
| naive | For each script in the suite, use 1) ft-naive-faultless, 2) ft-naive-merger, 3) ft-naive-regular to run it |
| base | For each script in the suite, use 1) ft-base-faultless, 2) ft-base-merger, 3) ft-base-regular to run it |
| optimized | For each script in the suite, use 1) ft-optimized-faultless, 2) ft-optimized-merger, 3) ft-optimized-regular to run it |
| correctness | This assumes dish is already run. Because each script can produce a large output, we check correctness after running each script. If there's no diff, then we remove the "target output" while keeping the "baseline output" for future correctness checks |
| clean | This cleans the all outputs. Run it when outputs folder get too large (usually no need to) |

## run.distr.ft.sh Explanation
They can be run in any combination, and here are some advised usage patterns/combinations.
**correctness checks should be run when updating the ft implementation, and for multiple runs with the same implementation to get a std of execution times, don't check correctness**
- ./run.distr.ft.sh sanity
    - This checks if dish has the same output as bash
    - Once we run this, we can use dish output as baseline
    - **When you run with sanity option, no need to run with any other options. It will run each script in the suite with bash and dish then compare their outputs**
- ./run.distr.ft.sh correctness [naive][base][optimized]
    - This assumes dish is already run
    - Because each script can produce a large output, we check correctness after running each script. If there's no diff, then we remove the "target output" while keeping the "baseline output" for future correctness checks
 - ./run.distr.ft.sh clean
    - This cleans the all outputs. Run it when outputs folder get too large (usually no need to)
