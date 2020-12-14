# randomURL.py
# Finds and displays a random webpage.
# FB - 201009127
import random
import urllib2

max_num = 12000000
max_value = 100000000
num_per_line = 10
#print max_lines
def genRandom(max_num, factor):
    f = open("test_data_" + str(int(100*factor)), "w");
    i = 0
    count = 0
    while(i < max_num*factor):
       count += 1
       r = random.randint(0,max_value)
       f.write(str(r))
       i += 1
       if count % num_per_line == 0:
          f.write("\n")
       #the last number are not followed by a blank
       elif i != max_num*factor:
          f.write(' ')
    f.close()

for i in [1.2]:
    genRandom(max_num,i)

"""
f = open("random_data_" + str(int(100*0.01)), "r");
for line in f.readlines():
   s = line.split(" ");
   for i in range (0, len(s)):
       print int(s[i])
"""   
