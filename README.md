# Evaluation_of_Spark_on_kubernetes
In the bare metal directory, there are four scripts for different experiments. You can run them directly.
In the kube directory, install_kubernetes_19.sh will install packages of kuberentes on a cluster of serval nodes, 
and init_kubernetes.sh creates a kubernetes-based cloud platform.
There are some experiments scripts for different experiments in the directory. 
By the way, collect.sh invoke collectL as a daemon when one experiment begin. 
kill.sh will kill all pods including driver pods after an experiment finishes.
