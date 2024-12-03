#!/bin/bash
# tag: nginx logs
# IN=${IN:-/dependency_untangling/log_data}
# OUT=${OUT:-$PASH_TOP/evaluation/distr_benchmarks/dependency_untangling/input/output/nginx-logs}
mkdir -p $2

for log in $(hdfs dfs -ls -C "$1"); do
    out_basename="$2/$(basename "$log" .log)"

    # Get ips who use crawler bot to crawl the server
    hdfs dfs -cat -ignoreCrc "$log" | grep -E "Googlebot|Bingbot|Baiduspider|Yandex|ia_archiver" | cut -d " " -f1 | sort | uniq -c | sort -rn  >> "${out_basename}_crawlers.out"
    
    # Most requested URLs ########
    # hdfs dfs -cat -ignoreCrc "$log" | awk -F\" "{print \$2}" | awk "{print \$2}" | sort | uniq -c | sort -r  >> "${out_basename}_frequent_url.out"

    # Find successful links
    hdfs dfs -cat -ignoreCrc "$log" | awk "\$9 ~/200/" | cut -d " " -f7 | sort | uniq -c | sort -rn >> "${out_basename}_success.out"

    # Find broken links
    hdfs dfs -cat -ignoreCrc "$log" | awk "\$9 ~/404/" | cut -d " " -f7 | sort | uniq -c | sort -rn >> "${out_basename}_broken.out"
  
    # Find 502 (bad-gateway) we can run following command:
    hdfs dfs -cat -ignoreCrc "$log" | awk "(\$9 ~ /502/)" | awk "{print \$7}" | sort | uniq -c | sort -r >> "${out_basename}_bad_gateway.out"
    
    # Who are requesting broken links (or URLs resulting in 502)
    hdfs dfs -cat -ignoreCrc "$log" | awk -F\" "(\$2 ~ \"/wp-admin/install.php\"){print \$1}" | awk "{print \$1}" | sort | uniq -c | sort -r >> "${out_basename}_requester.out"
    
    # 404 for php files -mostly hacking attempts
    hdfs dfs -cat -ignoreCrc "$log" | awk "\$9 ~ /404/" | awk -F\" "(\$2 ~ \"^GET .*\.php\")" | awk "{print \$7}" | sort | uniq -c | sort -r  >> "${out_basename}_hacking.out"
done

echo "done";
