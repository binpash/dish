#!/bin/bash

remote_addr=${1?"ERROR: No cloudlab remote machine address given"}
user=${2?"ERROR: No cloudlab user given"}
docker_container="docker-hadoop-client-1"
gen_plot_path="\$DISH/evaluation/gen_plot.py"
res_folder="plots"

# SSH into the remote machine, run the script inside the Docker container
ssh $user@$remote_addr "
    # Run the Python gen_plot script inside the remote client docker container
    docker exec $docker_container /bin/bash -c 'python3 \$DISH/evaluation/gen_plot.py && echo gen_plot.py executed successfully'

    # Copy generated plots from remote docker container to remote machine
    docker cp "$docker_container":\$DISH_TOP/evaluation/$res_folder /$res_folder
"

# transfer res_folder from remote machine to the local machine
scp -r $user@$remote_addr:/$res_folder ./$res_folder

