#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from __future__ import print_function

import sys
import time
import re
import numpy as np
from datetime import datetime

from pyspark import SparkContext


def parseVector(line):
    return np.array([float(x) for x in line.split()])


def closestPoint(p, centers):
    bestIndex = 0
    closest = float("+inf")
    for i in range(len(centers)):
        tempDist = np.sum((p - centers[i]) ** 2)
        if tempDist < closest:
            closest = tempDist
            bestIndex = i
    return bestIndex


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: kmeans <file> <data> <k> <convergeDist> <save_execution_time>", file=sys.stderr)
        exit(-1)

    print("""WARN: This is a naive implementation of KMeans Clustering and is given
       as an example! Please refer to examples/src/main/python/mllib/kmeans.py for an example on
       how to use MLlib's KMeans implementation.""", file=sys.stderr)

    sc = SparkContext(appName="PythonKMeans")
    f_exe_time = open(sys.argv[4], "w")
    start_time = str(datetime.now())
    start_millis = int(round(time.time() * 1000))

    lines = sc.textFile(sys.argv[1])
    data = lines.map(parseVector).cache()
    partition_num = data.getNumPartitions()
    end_millis = int(round(time.time() * 1000))
    end_time = str(datetime.now())
    f_exe_time.write("lines.map,execution time(ms),%s,partition number,%s\n" %(str(end_millis - start_millis),str(partition_num)))
    
    K = int(sys.argv[2])
    convergeDist = float(sys.argv[3])

    tmp_start_millis = int(round(time.time() * 1000))
    kPoints = data.takeSample(False, K, 1)
    tmp_end_millis = int(round(time.time() * 1000))
    f_exe_time.write("data.takseSample,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis - tmp_start_millis),str(partition_num)))

    tempDist = 1.0
    
    iter_num = 0
    while tempDist > convergeDist and iter_num < 3:
        tmp_start_millis = int(round(time.time() * 1000))
        closest = data.map(lambda p: (closestPoint(p, kPoints), (p, 1)))
        partition_num = closest.getNumPartitions()
        tmp_end_millis = int(round(time.time() * 1000))
        f_exe_time.write("data.map,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis - tmp_start_millis),str(partition_num)))

        tmp_start_millis = int(round(time.time() * 1000))
        pointStats = closest.reduceByKey(lambda p1_c1, p2_c2: (p1_c1[0] + p2_c2[0], p1_c1[1] + p2_c2[1]))
        partition_num = pointStats.getNumPartitions()
        tmp_end_millis = int(round(time.time() * 1000))
        f_exe_time.write("closest.reduceByKey,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis-tmp_start_millis),str(partition_num)))

        tmp_start_millis = int(round(time.time() * 1000))
        newPointsRDD = pointStats.map(lambda st: (st[0], st[1][0] / st[1][1]))
        partition_num = newPointsRDD.getNumPartitions()
        tmp_end_millis = int(round(time.time() * 1000))
        f_exe_time.write("newPointsRDD,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis - tmp_start_millis),str(partition_num)))

        tmp_start_millis = int(round(time.time() * 1000))
        newPoints = newPointsRDD.collect()
        tmp_end_millis = int(round(time.time() * 1000))
        f_exe_time.write("newPoints,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis - tmp_start_millis),str(partition_num)))

        tmp_start_millis = int(round(time.time() * 1000))
        tempDist = sum(np.sum((kPoints[iK] - p) ** 2) for (iK, p) in newPoints)

        for (iK, p) in newPoints:
            kPoints[iK] = p
        tmp_end_millis = int(round(time.time() * 1000))
        f_exe_time.write("KPoints,execution time(ms),%s,partition number,%s\n" %(str(tmp_end_millis - tmp_start_millis),str(partition_num)))

        iter_num = iter_num + 1

    #print("Final centers: " + str(kPoints))

    end_millis = int(round(time.time() * 1000))
    end_time = str(datetime.now())
    f_exe_time.write("total,execution time(ms),%s,start time,%s,end time,%s\n" %(str(end_millis - start_millis),start_time,end_time))
    f_exe_time.close()
    sc.stop()

