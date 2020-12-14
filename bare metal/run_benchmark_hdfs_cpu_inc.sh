#!/bin/bash

master_ip=192.168.10.4
slave1_ip=192.168.10.11
slave2_ip=192.168.10.12
slave3_ip=192.168.10.13
slave4_ip=192.168.10.14
slave5_ip=192.168.10.15
slave6_ip=192.168.10.16

master_hostname=k8s-master
result_hostname=k8s-master
slave1_hostname=worker-1
slave2_hostname=worker-2
slave3_hostname=worker-3
slave4_hostname=worker-4
slave5_hostname=worker-5
slave6_hostname=worker-6
hdfs_dir=hdfs://192.168.10.201:9000/user/test_data

####--------------very important notation--------------------
#Exception in thread "main" org.apache.spark.SparkException: Cluster deploy mode is currently not 
#supported for python applications on standalone clusters.
#we luach the benchmark on k8s-master and
#spark master will actually run slave2_hostname
 
#node0 is the master
nodes=($slave2_hostname $slave3_hostname $slave4_hostname $slave1_hostname $slave6_hostname)
node_num=${#nodes[@]}
range=`expr $node_num - 1`


execution_dir=/opt/spark
benchmark_dir=/home/304lab_spark/spark_benchmark
app_dir=/tmp/spark_benchmark
monitor_dir=/tmp/monitor

monitor_script=collectl.sh
kill_script=kill_bash.sh

collectl_cpu=$monitor_dir/cpu.txt
collectl_disk=$monitor_dir/disk.txt
collectl_mem=$monitor_dir/mem.txt
collectl_net=$monitor_dir/net.txt
sar_file=$monitor_dir/sar

sync_time(){
   for i in $( eval echo {0..$range} ); do        
       node=${nodes[$i]}
       echo "sync time of $node"
       sudo sshpass -p 123456 ssh $node "ntpdate -u $master_hostname"
   done
}

mask_ssh_confirm(){
   #for master
   sudo bash -c 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config'
   #for other hosts.
   for i in $( eval echo {1..$range} ); do
       node=${nodes[$i]}
       sudo ssh $node "bash -c 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config'"
   done
}


clear_cache(){
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo clear cache on $node
       sudo sshpass -p 123456 ssh -t $node "sync; sudo sysctl vm.drop_caches=1"
    done
}

start_monitor(){
    echo "start monitor"
    #cd /tmp/monitor_httpd; python monitor_httpd.py &  
    #sudo ssh -p $master_port $master_host  "sudo $monitor_dir/get_pods_num.sh $monitor_dir/pods_num" &  
    #sudo $monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file &
    sudo sshpass -p 123456 ssh ${nodes[0]}  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" & 
    sudo sshpass -p 123456 ssh ${nodes[1]}  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh ${nodes[2]}  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh ${nodes[3]}  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh ${nodes[4]}  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
}

clean_monitor(){
    #echo "clean monitor on master"
    #sudo $monitor_dir/$kill_script collectl
    #sudo $monitor_dir/$kill_script sar

   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo "clear monitor on" $node  
       sudo sshpass -p 123456 ssh -t $node "sudo $monitor_dir/$kill_script collectl"
       sudo sshpass -p 123456 ssh -t $node "sudo $monitor_dir/$kill_script sar"
   done
}


copyFiles(){
   #echo "copy files on master"
   #mkdir -p $monitor_dir
   #cd  $benchmark_dir; 
   #cp  $monitor_script $kill_script $monitor_dir

   #sudo ssh $master_hostname  "mkdir -p $monitor_dir"
   
   
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo "make monitor dir on" $node 
       sudo sshpass -p 123456 ssh $node "mkdir -p $monitor_dir; mkdir -p $app_dir"
       cd  $benchmark_dir;                              
       sudo sshpass -p 123456 scp $monitor_script $kill_script $node:$monitor_dir 
       cd ..
       echo "copy codes and data on" $node
       sudo sshpass -p 123456 scp -r $benchmark_dir $node:/tmp
   done
}

delFiles(){
  #echo "delete files on master"
  #delete files on master
  #sudo rm -r $monitor_dir;

  for i in $( eval echo {0..$range} ); do
     node=${nodes[$i]}
     echo "delete files" on $node
     sudo sshpass -p 123456 ssh -t $node  "sudo rm -r $monitor_dir; sudo rm -r $app_dir; sudo rm -r /tmp/spark-events/* sudo rm -r /tmp/spark.log";
  done
}

run_lr(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`

   #We submit the program on master node so that the driver will run on the node.
   echo "run lr benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $benchmark_dir/lr; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores"
}

run_kmeans(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`
   data=$hdfs_dir/run_kmeans/11440
   code=$hdfs_dir/run_kmeans/kmeans_nocache.py
   cluster_num=5
   conv=0.5
   result_loc=$monitor_dir/kmeans_result
   #client_num=1
   #We submit the program on master node so that the driver will run on the node.
   echo "run kmeans benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $app_dir/kmeans; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores $code $data $cluster_num $conv $result_loc $master_node $client_num"
}

run_sort(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`

   code=$hdfs_dir/run_sort/sort.py
   result_loc=$monitor_dir/sort_result
   data=$hdfs_dir/run_sort/10240
   #We submit the program on master node so that the driver will run on the node.
   echo "run sort benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $app_dir/sort; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores $code $data $result_loc $master_node $client_num"
}

run_wordcount(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`

   code=$hdfs_dir/run_wordcount/wordcount.py
   result_loc=$monitor_dir/wordcount_result
   data=$hdfs_dir/run_wordcount/10240
   #We submit the program on master node so that the driver will run on the node.
   echo "run wordcount benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $app_dir/wordcount; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores $code $data $result_loc $master_node $client_num"
}

run_pagerank(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`

   code=$hdfs_dir/run_pagerank/pagerank.py
   iter=5

   #We submit the program on master node so that the driver will run on the node.
   echo "run pagerank benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $app_dir/pagerank; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores $code $data $iter $master_node"
}


run_sql_join(){
   driver_cores=1
   driver_memory=2048M
   executor_cores=1
   executor_memory=2048M
   total_cores=`expr $executor_num \* $executor_cores`

   code=$hdfs_dir/run_sql_join/sql_join.py
   data=$hdfs_dir/run_sql_join/users.txt-2180
   data2=$hdfs_dir/run_sql_join/urls.txt-360
   result_loc=$monitor_dir/sql_join_result
   #We submit the program on master node so that the driver will run on the node.
   echo "run sql_join benchmark"
   master_node=${nodes[0]}
   sudo sshpass -p 123456  ssh $master_node "cd $app_dir/sql_join; ./run.sh $driver_cores $driver_memory $executor_cores $executor_memory $total_cores $code $data $data2 $result_loc $master_node $client_num"
}


start_master(){
   #node0 is the master
   node=${nodes[0]}
   echo "start master" on $node
   sshpass -p 123456 ssh $node "cd $execution_dir/sbin; ./start-master.sh"
   #close spark history server
   sshpass -p 123456 ssh $node "mkdir -p /tmp/spark-events; cd $execution_dir/sbin; ./start-history-server.sh"
}

close_master(){
   #node0 is the master
   node=${nodes[0]}
   echo "close master" on $node
   sshpass -p 123456 ssh $node "cd $execution_dir/sbin; ./stop-master.sh"
   sshpass -p 123456 ssh $node "cd $execution_dir/sbin; ./stop-history-server.sh"
}

start_slaves(){
   #master is also a slave in the cluster
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo "start slave" on $node
       sshpass -p 123456 ssh $node "mkdir -p /tmp/spark-events; cd $execution_dir/sbin; ./start-slave.sh ${nodes[0]}:7077"
   done
}

close_slaves(){
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo "close slave" on $node
       sshpass -p 123456 ssh $node "cd $execution_dir/sbin; ./stop-slave.sh;"
   done
}

transFiles(){
   echo "transfer Files back"
   result_hostname=$result_hostname
   dest_dir=/home/results/$storage;
   #sudo ssh -p $result_port $result_host "mkdir -p $dest_dir"
   mkdir -p $dest_dir
   cp /etc/hosts $dest_dir
   #cp  $monitor_dir/* $dest_dir
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       echo "transfer files back" on $node
       sudo sshpass -p 123456 ssh $node "sshpass -p 123456 scp -r $monitor_dir/* $result_hostname:$dest_dir";
       sudo sshpass -p 123456 ssh $node "sshpass -p 123456 scp -r /tmp/spark.log $result_hostname:$dest_dir/spark.log-$node";
       #copy spark history 
       sudo sshpass -p 123456 ssh $node "sshpass -p 123456 scp -r /tmp/spark-events/* $result_hostname:$dest_dir";
   done
}

#run_kmeans run_sql_join

test(){
   for count in 4 5; do
      for executor_num in 5 10 ; do
         for run_benchmark in run_kmeans run_sort run_wordcount; do
                client_num=1
                #data=$hdfs_dir/$run_benchmark/$data_size
                delFiles
                clear_cache
                copyFiles
                clean_monitor
                start_monitor
                $run_benchmark
                clean_monitor
                storage=E$executor_num-$count-11440-$run_benchmark-cpuinc
                echo $storage
                transFiles
                delFiles
          done
          sleep 2m
     done
   done
}



#sleep 8h
#copyFiles
close_slaves
close_master
sync_time
start_master
start_slaves

#run_kmeans
#sleep 2h
test
close_slaves
close_master


