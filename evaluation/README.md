
### Description of Contents

- **suite/**: Contains all the scripts and utilities for the project.
  - **scripts/**: Directory for individual scripts.
    - **script1.sh, script2.sh, script3.sh, ...**: Specific scripts to perform various tasks. Each script should be self-contained and executable.
  - **dependencies.sh**: Script to set up the environment or dependencies required by other scripts.
  - **inputs.sh**: Script to prepare or fetch the input data necessary for the execution of the main script.
  - **run.sh**: Main script to execute the core functionality of the project.
  - **verify.sh**: Script to verify the results or outputs produced by `run.sh`.
  - **cleanup.sh**: Script to clean up the environment, remove temporary files, or revert any changes made during the execution.

### How to Use

1. **Setup Dependencies**: First, ensure you have all dependencies and environment variables set up (Some suites has no dependencies).
    ```bash
    cd suite
    ./dependencies.sh
    ```

2. **Prepare Inputs**: Prepare or fetch the necessary input data (Both full and small inputs when apply).
    ```bash
    ./inputs.sh
    ```

3. **Run the Main Script**: Execute the core functionality. It creates hash files for each generated output file and then remove the output file to save disk space.
    ```bash
    ./run.sh [-d <debug flag for pash/dish/fish>] [--small <using small inputs>]
    ```

4. **Verify the Output**: Check the results to ensure correctness.
    ```bash
    ./verify.sh [--generate <generating dedicated hash folders>] [--small <using small inputs>]
    ```

5. **Cleanup**: Clean up the environment after the execution.
    ```bash
    ./cleanup.sh
    ```

### Notes


## How to Convert a Button from the Benchmark Repo to a Fish-Specific Repo

1. **In `inputs.sh`, store input files to HDFS**
    ```bash
    # Example command to store input files to HDFS
    hdfs dfs -put local_input_file.txt /path/in/hdfs/
    ```

2. **In `run.sh`, make sure to call pash/dish/fish with the relevant flags (can refer to existing buttons)**
    ```bash
    # Example command to run Fish with relevant flags
    fish -flag1 -flag2 /path/in/hdfs/input_file.txt
    ```

3. **In each script, make sure to read inputs from HDFS**
    ```bash
    # Example for reading input from HDFS in a script
    hdfs dfs -cat /path/in/hdfs/input_file.txt > local_input_file.txt
    
    # Rest of the script
    ```

4. **In `cleanup.sh`, make sure to also remove the files stored in HDFS**
    ```bash
    # Example command to remove files from HDFS
    hdfs dfs -rm /path/in/hdfs/input_file.txt
    ```

## For parallel pipeline suites, refer to to nlp, covid-mts, file-enc, media-conv, and log-analysis buttons.


