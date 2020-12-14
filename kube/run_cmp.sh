#!/bin/bash
#sleep 1h

cmp(){
/home/304lab_kubernetes/spark_benchmark_kubernetes/run_benchmark.sh
/home/304lab_spark/spark_benchmark/run_benchmark_hdfs.sh
}

cpu_inc_cmp(){
/home/304lab_kubernetes/spark_benchmark_kubernetes/run_benchmark_cpu_inc.sh
/home/304lab_spark/spark_benchmark/run_benchmark_hdfs_cpu_inc.sh
}

consolidation_cmp(){
/home/304lab_kubernetes/spark_benchmark_kubernetes/run_benchmark_consolidation.sh
/home/304lab_spark/spark_benchmark/run_benchmark_hdfs_consolidation.sh
}

#/home/304lab_spark/spark_benchmark/run_benchmark_hdfs_nocache.sh
#sleep 15m
#sleep 15h
cmp
#/home/304lab_kubernetes/spark_benchmark_kubernetes/run_benchmark_cpu_inc.sh
#sleep 15m
#cpu_inc_cmp
#consolidation_cmp

#./kube_run_sh
#./spark_run_sh


