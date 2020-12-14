#!/bin/bash
#!/bin/bash

master_hostname=k8s-master
time_server=k8s-master

master_ip=192.168.10.4
k8s_cluster_master=k8s://https://$master_ip:6443

#192.168.10.6  k8s-master myregistry.local
#192.168.110.6 k8s-master
worker1=192.168.10.11
worker2=192.168.10.12
worker3=192.168.10.13
worker4=192.168.10.14
worker5=192.168.10.15
worker6=192.168.10.16
store1=192.168.10.201
#192.168.10.202 store-2


slave1_hostname=thinkstation-e32-1
slave2_hostname=thinkstation-e32-2


nodes=($master_hostname $worker1 $worker2 $worker3 $worker4 $worker6)
#nodes=($master_hostname $slave2_hostname)
node_num=${#nodes[@]}
range=`expr $node_num - 1`

password=123456


benchmark_dir=/home/304lab_kubernetes/spark_benchmark_kubernetes
monitor_dir=/tmp/monitor

monitor_script=collectl.sh
kill_script=kill_bash.sh

collectl_cpu=$monitor_dir/cpu.txt
collectl_disk=$monitor_dir/disk.txt
collectl_mem=$monitor_dir/mem.txt
collectl_net=$monitor_dir/net.txt
sar_file=$monitor_dir/sar
save_startup=$monitor_dir/pod_startup

#data_dir=/home/test_data
hdfs_dir=hdfs://192.168.10.201:9000/user/test_data

sync_time(){
   for i in $( eval echo {0..$range} ); do        
       node=${nodes[$i]}
       echo "sync time of $node"
       sudo sshpass -p 123456 ssh $node "ntpdate -u $master_hostname"
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
    sudo sshpass -p 123456 ssh $worker2  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" & 
    sudo sshpass -p 123456 ssh $worker3  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh $worker4  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh $worker6  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &
    sudo sshpass -p 123456 ssh $worker1  "$monitor_dir/$monitor_script $collectl_cpu $collectl_mem $collectl_disk $collectl_net $sar_file" &

}

clean_monitor(){
    echo "clean monitor"
    sudo $monitor_dir/$kill_script collectl
    sudo $monitor_dir/$kill_script sar
    #sudo $monitor_dir/$kill_script pod_startup

   for i in $( eval echo {1..$range} ); do
       node=${nodes[$i]}
       echo clean monitor on $node
       sudo sshpass -p 123456 ssh -t $node "sudo $monitor_dir/$kill_script collectl"
       sudo sshpass -p 123456 ssh -t $node "sudo $monitor_dir/$kill_script sar"
   done
}

copyData(){
  for i in $( eval echo {1..$range} ); do
      node=${nodes[$i]}
      sudo sshpass -p 123456 scp -r $data_dir  $node:/home
  done
}

copyFiles(){
   echo "copy files"
   mkdir -p $monitor_dir
   cd  $benchmark_dir; 
   cp  $monitor_script $kill_script  $monitor_dir

   #sudo ssh $master_hostname  "mkdir -p $monitor_dir"
   cp -r $benchmark_dir /tmp
   #for history
   mkdir -p /tmp/spark-events
   for i in $( eval echo {1..$range} ); do
       node=${nodes[$i]}
       echo "make monitor dir" on $node
       sudo sshpass -p 123456 ssh $node  "mkdir -p $monitor_dir; mkdir -p /tmp/spark-events"
       cd $benchmark_dir; 
       sudo sshpass -p 123456 scp $monitor_script $kill_script $node:$monitor_dir
       cd ..
       sudo sshpass -p 123456 scp -r $benchmark_dir $node:/tmp
    done

}

delFiles(){
  echo "delete files"
  #delete files on master
  sudo rm -r $monitor_dir;
  sudo rm -r /tmp/spark_benchmark_kubernetes
  sudo rm -r /tmp/spark-events
  for i in $( eval echo {1..$range} ); do
      node=${nodes[$i]}
      echo delete files on $node
      sudo sshpass -p 123456 ssh -t $node "sudo rm -r $monitor_dir; sudo rm -r /tmp/spark-events; sudo rm -r /tmp/spark_benchmark_kubernetes";
 done
}

run_pagerank(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/pagerank

   code=$hdfs_dir/run_pagerank/pagerank.py
   #data=$hdfs_dir/run_kmeans/test_data_2190
   iter=10
   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num

   #run pagerank on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $iter $driver_memory $executor_request_cores $executor_memory $instance &
   { sleep 60s ; kubectl get pods -o wide | grep pagerank > $monitor_dir/pagerank_pods_distribution; python $benchmark_dir/pod_startup.py $save_startup ; } &
   wait
    
}

run_lr(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/lr

   code=$app_executor_dir/lr.py
   data=$hdfs_dir/run_lr/lr_train.csv 
   result_loc=$app_executor_dir/lr_result
   iter=30
   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num

   #run lr on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $iter $result_loc $driver_memory $executor_request_cores $executor_memory $instance &
   { sleep 40s ; kubectl get pods -o wide | grep lr > $monitor_dir/lr_pods_distribution ; python $benchmark_dir/pod_startup.py $save_startup ;  } &
   wait


   #echo "run lr benchmark"
   #$execution_dir/bin/spark-submit --master spark://$master_hostname:7077 \
   #                               $benchmark_dir/lr/lr.py $benchmark_dir/lr/lr_train.csv 5 $monitor_dir/lr_result
}

run_kmeans(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/kmeans
 
   code=$hdfs_dir/run_kmeans/kmeans.py
   data=$hdfs_dir/run_kmeans/4440
 
   cluster_num=5
   conv=0.5
   result_loc=$app_executor_dir/kmeans_result
   
   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num
   
   #run kmeans on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $cluster_num $conv $result_loc $driver_memory $executor_request_cores $executor_memory $instance $client_num &
   { sleep 60s ; kubectl get pods -o wide | grep kmeans > $monitor_dir/kmeans_pods_distribution; python $benchmark_dir/pod_startup.py $save_startup ; } &
   wait
   #echo "delete kmeans spark cluster"
   #kubectl delete rc spark-master-controller-kmeans
   #kubectl delete rc spark-worker-controller-kmeans
}

run_sort(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/sort

   code=$hdfs_dir/run_sort/sort.py
   data=$hdfs_dir/run_sort/5120

   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num

   #run sort on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $driver_memory $executor_request_cores $executor_memory $instance $client_num&
   { sleep 60s ; kubectl get pods -o wide | grep sort > $monitor_dir/sort_pods_distribution; python $benchmark_dir/pod_startup.py $save_startup ; } &
   wait
   #echo "delete kmeans spark cluster"
   #kubectl delete rc spark-master-controller-kmeans
   #kubectl delete rc spark-worker-controller-kmeans
}

run_wordcount(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/wordcount

   code=$hdfs_dir/run_wordcount/wordcount.py
   data=$hdfs_dir/run_wordcount/5120

   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num

   #run wordcount on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $driver_memory $executor_request_cores $executor_memory $instance $client_num&
   { sleep 60s ; kubectl get pods -o wide | grep wordcount > $monitor_dir/wordcount_pods_distribution; python $benchmark_dir/pod_startup.py $save_startup ; } &
   wait
   #echo "delete kmeans spark cluster"
   #kubectl delete rc spark-master-controller-kmeans
   #kubectl delete rc spark-worker-controller-kmeans
}


run_sql_join(){
   app_executor_dir=/tmp/spark_benchmark_kubernetes/sql_join

   code=$app_executor_dir/sql_join.py
   data=$hdfs_dir/run_sql_join/users.txt-1080
   data2=$hdfs_dir/run_sql_join/urls.txt-180
   result_loc=$app_executor_dir/sql_join_result
  
   driver_memory=2g
   executor_request_cores=1
   executor_memory=2g
   instance=$instance_num

   #run lr on spark cluster on kubernetes
   $app_executor_dir/run.sh $k8s_cluster_master $code $data $data2 $result_loc $driver_memory $executor_request_cores $executor_memory $instance $client_num&
   { sleep 60s ; kubectl get pods -o wide | grep sqljoin > $monitor_dir/sql_join_pods_distribution ; python $benchmark_dir/pod_startup.py $save_startup ; } &
   wait

   #echo "run sql join benchmark"
   #$execution_dir/bin/spark-submit --master spark://$master_hostname:7077 \
   #                               $benchmark_dir/sql_join/sql_join.py $benchmark_dir/sql_join/users.txt_2180 $benchmark_dir/sql_join/urls.txt_180 \
   #                               $monitor_dir/sql_join_result
}


delDriverPods(){
   pods=($(kubectl get pods| grep 'driver \| -exec-' | awk 'NR>0 { printf sep $1; sep=" "}'))
   if [ ${#pods[@]} -gt 0 ]; then  # $n is still undefined!
      for pod in "${pods[@]}"; do
         kubectl delete pods $pod 
      done
   fi
   sleep 2m
   pods=($(kubectl get pods| grep 'driver \| -exec-' | awk 'NR>0 { printf sep $1; sep=" "}'))
   if [ ${#pods[@]} -gt 0 ]; then  # $n is still undefined!
      for pod in "${pods[@]}"; do
          echo "delete" $pod forcelly
   	  kubectl delete pods $pod --grace-period=0 --force
      done
   fi
}

getDriverLog(){
   pods=($(kubectl get pods| grep driver | awk 'NR>0 { printf sep $1; sep=" "}'))
   if [ ${#pods[@]} -gt 0 ]; then  # $n is still undefined!
      for pod in "${pods[@]}"; do
         kubectl logs $pod > $dest_dir/$pod-log
      done
   fi    
}

transFiles(){
   echo "transfer Files back"
   result_hostname=$master_hostname
   dest_dir=/home/results/$storage;
   #sudo ssh -p $result_port $result_host "mkdir -p $dest_dir"
   mkdir -p $dest_dir
   cp /etc/hosts $dest_dir
   cp  $monitor_dir/* $dest_dir

   for i in $( eval echo {1..$range} ); do
       node=${nodes[$i]}
       echo "transfer file back" on $node
       sudo sshpass -p 123456 ssh  $node "sshpass -p 123456 scp -r $monitor_dir/* $result_hostname:$dest_dir";
       sudo sshpass -p 123456 ssh  $node "sshpass -p 123456 scp -r /tmp/spark-events/* $result_hostname:$dest_dir";
       for result_dir in kmeans; do
          sudo sshpass -p 123456 ssh  $node "sshpass -p 123456 scp -r /tmp/spark_benchmark_kubernetes/$result_dir/*_result $result_hostname:$dest_dir";
      done
   done
   
   getDriverLog

}

test(){
   for run_benchmark in run_kmeans; do
       delFiles
       clear_cache
       delDriverPods
       copyFiles
       clean_monitor
       start_monitor
       $run_benchmark
       clean_monitor
       storage=kube_$run_benchmark
       echo $storage
       transFiles
       delDriverPods
       delFiles
  done
}

test_instance(){
   #copyData
   sync_time
   suffix=consolidation
   for count in 1 2 3 4 5; do
      for client_num in 1 6; do
	   for run_benchmark in run_kmeans run_wordcount run_sort run_sql_join; do
               instance_num=3
              #for data_size in 4440; do
               #data=$hdfs_dir/$run_benchmark/$data_size
	       delFiles
	       clear_cache
	       delDriverPods
	       copyFiles
	       clean_monitor
	       start_monitor
	       $run_benchmark
	       clean_monitor
	       storage=I$client_num-$count-1000-$run_benchmark$suffix
	       echo $storage
	       transFiles
               delDriverPods
	       #delFiles
	   done
         sleep 2m
      done 
   done
}


#run_lr
#sync_time
#sleep 4h
test_instance
#delFiles
#copyFiles
#clean_monitor
#delDriverPods
#instance_num=5
#run_kmeans
#copyFiles
#storage=run_pagerank
#run_pagerank
#delDriverPods
#python $benchmark_dir/pod_startup.py save_startup_time;
