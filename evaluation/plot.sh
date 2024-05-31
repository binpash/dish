#!/bin/bash

remote_addr=${1?"ERROR: No cloudlab remote machine address given"}
user=${2?"ERROR: No cloudlab user given"}
user_dir="/users/$user" # path to ~ on remote machine for the user
docker_container="docker-hadoop-client-1"
DISH_TOP="/opt/dish"
gen_plot_path="$DISH_TOP/evaluation/gen_plot.py"
res_folder="plots"


# SSH into the remote machine, run the script inside the Docker container
ssh $user@$remote_addr "
    # Run the Python gen_plot script inside the remote client docker container
    docker exec $docker_container python3 $gen_plot_path &&
    
    # Copy generated plots from remote docker container to remote machine
    docker cp "$docker_container":$DISH_TOP/evaluation/$res_folder $user_dir
"

# transfer res_folder from remote machine to the local machine
scp -r $user@$remote_addr:$user_dir/$res_folder ./$res_folder

