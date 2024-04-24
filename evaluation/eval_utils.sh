#!/bin/bash

# Host and port information
host="namenode"
port=9870

get_active_nodes() {
    # Query string for Hadoop JMX information
    query="Hadoop:service=NameNode,name=NameNodeInfo"

    # Construct the URL for the HTTP GET request
    url="http://${host}:${port}/jmx?qry=${query}"

    # Get the threshold value from command line arguments
    lastContactThreshold=${1:-10}  # Default threshold of 10 seconds

    # Send the HTTP GET request and capture the response
    response=$(curl -s "${url}")
    
    # Extract the LiveNodes data from the JSON response
    live_nodes_json=$(echo "$response" | jq -r '.beans[0].LiveNodes')

    # Initialize an array to store the active node IPs
    active_nodes=()

    # Iterate over each key (node) in the LiveNodes JSON
    for node in $(echo "$live_nodes_json" | jq -r 'keys[]'); do
        # Get the last contact time and info address for each node
        last_contact=$(echo "$live_nodes_json" | jq -r ".\"$node\".lastContact")
        info_addr=$(echo "$live_nodes_json" | jq -r ".\"$node\".infoAddr")

        # Get the IP address (excluding the port)
        node_ip=$(echo "$info_addr" | cut -d ':' -f 1)

        # If the last contact time is less than the threshold, consider it active
        if [[ "$last_contact" -lt "$lastContactThreshold" ]]; then
            active_nodes+=("$node_ip")
        fi
    done
    echo "${active_nodes[@]}"
}

get_num_active_nodes() {
    active_nodes=($(get_active_nodes))
    num_active_nodes=${#active_nodes[@]}
    echo $num_active_nodes
}

update_config() {
    active_nodes=($(get_active_nodes))  # Wrap in parentheses to create an array

    # Create a JSON object for the active nodes in the "workers" format
    worker_json=$(jq -n '{ "workers": {} }')

    # Assign incremental IDs to each worker
    for i in "${!active_nodes[@]}"; do
        worker_id="worker$((i + 1))"
        worker_ip="${active_nodes[$i]}"  # Correctly reference array elements

        # Add the worker information to the JSON object
        worker_json=$(echo "$worker_json" | jq --arg id "$worker_id" --arg host "$worker_ip" '{ "workers": (.workers + {($id): { "host": $host, "port": 65432 }}) }')
    done

    # Write the JSON output to a file
    output_file="${DISH_TOP}/pash/cluster.json"  # Fix variable interpolation
    echo "$worker_json" > "$output_file"
}

config_path="$PASH_TOP/cluster.json"
get_merger_worker_host() {
  merger_worker_host=$(awk -F'"' '/host/ && NR==4 {print $4}' $config_path)
  echo "$merger_worker_host"
}

get_regular_worker_host() {
  regular_worker_host=$(awk -F'"' '/host/ && NR==8 {print $4}' $config_path)
  echo "$regular_worker_host"
}


check_correctness() {
  script_name="$1"
  out_baseline="$2"
  out_target="$3"
  echo "📝  Checking output for $script_name: $out_baseline and $out_target"

  # Check if out files exist
  if [ ! -f "$out_baseline" ]; then
      echo "    Error: $out_baseline not found"
      exit 1
  fi
  if [ ! -f "$out_target" ]; then
      echo "    Error: $out_target not found"
      exit 1
  fi

  
  # Perform diff between current configuration file and seq.out
  diff_result=$(diff "$out_baseline" "$out_target")
  
  # Check if there are differences
  if [ -n "$diff_result" ]; then
    #   echo "$diff_result"
      echo "    ❌ Differences found:"
      return 1
  else
      echo "    ✅ No differences found"
      return 0
  fi
}

# If option "correctness" is specified, check for out_baseline vs out_target
#       if no diff, removing out_target
#       if diff, don't remove out_target for debugging
# else, remove out_target to save SSD
handle_outputs() {
  script_name="$1"
  out_baseline="$2"
  out_target="$3"
  if [[ "$@" == *"correctness"* ]]; then
    check_correctness "$script_name" "$out_baseline" "$out_target"
    if [[ "$?" == 1 ]]; then
      echo "    Output file "$out_target" is not removed for debugging"
      # Return on the first diff
      # exit 1
    else
      rm $out_target
      echo "    Output file "$out_target" is removed"
    fi
  else
    if [[ "$@" == *"debug"* ]]; then
        echo "    Output file "$out_target" is not removed for debugging"
    else
        rm $out_target
        echo "Output file "$out_target" is removed"
    fi
  fi   
}

# Function to check if an IP address has a valid PTR record
has_ptr_record() {
    ip_address=$1
    # Run dig to perform a reverse DNS lookup
    dig_output=$(dig -x "$ip_address")

    # Check if the output contains 'status: NOERROR'
    if echo "$dig_output" | grep -q "status: NOERROR"; then
        return 0
    else
        return 1
    fi
}


# Assumption: between 2 invocations of this function, kill must be run on the datanode image
#             such that the old datanode image exits and a new one is started
#             therefore we expect the array of active datanodes to be different
# Breaking this assumption can lead to livelock
# arg1: number of active nodes expected in the configuration
# arg2: original active nodes as returned by get_active_nodes, among which one will be replaced 
wait_for_update_config() {
  expected_num_nodes=$1
  shift
  original_active_nodes="$@"
  echo "original nodes: $original_active_nodes"

  # Loop until the number of active nodes matches the expected number and they are different from the original ones
  while true; do
    num_nodes=$(get_num_active_nodes)
    active_nodes=$(get_active_nodes)

    # Check if the count matches the expected number and active_nodes is different from the original_active_nodes
    if [[ "$num_nodes" -eq "$expected_num_nodes" && "$active_nodes" != "$original_active_nodes" ]]; then
        echo "Finished re-configuring cluster with active nodes: $active_nodes"

        # Even when num_active_nodes=expected, it can still be 2/3 in datanode replicas

        # Loop until a valid PTR record is found
        active_nodes=($(get_active_nodes))
        for target_ip in "${active_nodes[@]}"; do
            while true; do
            if has_ptr_record "$target_ip"; then
                echo "PTR record found for IP: $target_ip."
                break  # Exit the loop once a PTR record is found
            else
                echo "Waiting for replacement worker $target_ip to settle down have a valid PTR record..."
                sleep 5 
            fi
            done
        done
        # Call the update_config function
        update_config
        break
    else
      echo "Waiting for re-configuration to finish..."
      sleep 10
    fi
  done
}
