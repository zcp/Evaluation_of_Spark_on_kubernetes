#!/bin/bash

execution_dir=/opt/spark

driver_cores=$1
driver_memory=$2
executor_cores=$3
executor_memory=$4
total_cores=$5

code=$6
data=$7
result_loc=$8
master_hostname=$9
client_num=${10}

run_app(){
   echo "run wordcount benchmark"
   $execution_dir/bin/spark-submit --master spark://$master_hostname:7077 \
                                   --driver-cores $driver_cores  \
                                   --driver-memory $driver_memory  \
                                   --executor-cores $executor_cores \
                                   --executor-memory $executor_memory \
                                   --total-executor-cores $total_cores \
                                   --conf "spark.executor.extraJavaOptions=-XX:+PrintGCDetails -XX:+PrintGCTimeStamps" \
                                   $code $data
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





