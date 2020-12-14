#!/bin/bash

execution_dir=/opt/spark

driver_cores=$1
driver_memory=$2
executor_cores=$3
executor_memory=$4
total_cores=$5

code=$6
data=$7
cluster_num=$8
conv=$9
result_loc=${10}
master_hostname=${11}
client_num=${12}

run_app(){
 
   echo "run kmeans benchmark"
  
   $execution_dir/bin/spark-submit --master spark://$master_hostname:7077 \
                                   --driver-cores $driver_cores  \
                                   --driver-memory $driver_memory  \
                                   --executor-cores $executor_cores \
                                   --executor-memory $executor_memory \
                                   --total-executor-cores $total_cores \
				   --conf "spark.executor.extraJavaOptions=-XX:+PrintGCDetails -XX:+PrintGCTimeStamps" \
                                   $code $data $cluster_num $conv $result_loc
}


case $client_num in
     1)
     run_app 
     ;;
     2)
     run_app &
     run_app &
     wait
     ;; 
     4)
     run_app &
     run_app &
     run_app &
     run_app &
     wait
     ;;
     5)
     run_app &
     run_app &
     run_app &
     run_app &
     run_app &
     wait
     ;;
     6)
     run_app &
     run_app &
     run_app &
     run_app &
     run_app &
     run_app &
     wait 
     ;;
     *)
     run_app
     ;;
esac  






