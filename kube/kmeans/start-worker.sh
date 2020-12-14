#!/bin/bash
/opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://10.244.2.30:7077 --webui-port 8081
