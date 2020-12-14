# randomURL.py
# Finds and displays a random webpage.
# FB - 201009127
import random
import urllib2
import os
"""
0.0 0.0 0.0
0.1 0.1 0.1
0.2 0.2 0.2
9.0 9.0 9.0
9.1 9.1 9.1
9.2 9.2 9.2
"""

#generate a 100M file
max_lines = 20000
#print max_lines
dimensions = 20
def gen3D(max_lines, factor):
    f_name = "test_data"
    f = open(f_name, "w");
    i = 0
    while(i < max_lines*factor):
       s = ""
       for dim in range(0, dimensions):
           x = str(round(random.uniform(0,max_lines), 1))
           if s == "":
              s = x
           else:
              s = s + "\t" + x
       f.write(s + "\n")
       i += 1
    f.close()

    size = os.path.getsize(f_name)
    size = (int(size/(1000*1000))/10)*10
    print size
    os.rename(f_name, f_name +"_" + str(size))

for i in [25]:
    gen3D(max_lines,i)


