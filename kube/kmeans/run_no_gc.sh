#!/bin/bash
#deploy a spark appliation to kubernetes
#./run code data storage_file memory_list core_number

#code=local:///tmp/kmeans/kmeans.py  
master=$1
code=$2
data=$3
iter=$4
conv=$5
result_loc=$6

driver_memory=$7
executor_request_cores=$8
executor_memory=$9
instance=${10}
client_num=${11}

run_app(){
   echo code: $code, data: $data, iter: $iter, convergeDist: $conv, result_loc: $result_loc, request_cores: $executor_request_cores, client_num:$client_num
   echo executor_request_cores: $executor_request_cores, executor_memory: $executor_memory, instance: $instance
   #cd /opt/spark
   arg=$1
   /opt/spark/bin/spark-submit \
      --master $master \
      --deploy-mode cluster \
      --name kmeans$arg \
      --conf spark.executor.instances=$instance \
      --conf spark.driver.cores=1 \
      --conf spark.driver.memory=$driver_memory \
      --conf spark.executor.cores=1 \
      --conf spark.executor.memory=$executor_memory \
      --conf spark.eventLog.enabled=true \
      --conf spark.eventLog.dir=/tmp/spark-events \
      --conf spark.kubernetes.node.selector.role=worker \
      --conf spark.kubernetes.executor.request.cores=$executor_request_cores \
      --conf spark.kubernetes.executor.limit.cores=$executor_request_cores \
      --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark  \
      --conf spark.kubernetes.driver.volumes.hostPath.tmp.mount.path=/tmp  \
      --conf spark.kubernetes.driver.volumes.hostPath.tmp.options.path=/tmp \
      --conf spark.kubernetes.executor.volumes.hostPath.tmp.mount.path=/tmp  \
      --conf spark.kubernetes.executor.volumes.hostPath.tmp.options.path=/tmp \
      --conf spark.kubernetes.container.image=myregistry.local:5000/spark_kube2:test3 \
      $code $data $iter $conv $result_loc
}


case $client_num in
     1)
     run_app 1
     ;;
     2)
     run_app 1 &
     run_app 2 &
     wait
     ;; 
     4)
     run_app 1 &
     run_app 2 &
     run_app 3 &
     run_app 4 &
     wait
     ;;
     5)
     run_app 1 &
     run_app 2 &
     run_app 3 &
     run_app 4 &
     run_app 5 &
     wait
     ;;
     6)
     run_app 1 &
     run_app 2 &
     run_app 3 &
     run_app 4 &
     run_app 5 &
     run_app 6 &
     wait 
     ;;
     *)
     run_app 1
     ;;
esac  
