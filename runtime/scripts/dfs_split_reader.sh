command="$DISH_TOP/runtime/bin/dfs_split_reader $@"
echo $command >&2
$command
