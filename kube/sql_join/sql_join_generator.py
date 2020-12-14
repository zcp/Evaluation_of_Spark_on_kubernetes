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


#users data: userID url
#url data: url 

def genUsers(n_users, f_name):
    f = open(f_name, "w");
    i = 0
    while(i < n_users):
        ip0 = str(random.randint(0, 10))
        ip1 = str(random.randint(0, 10))
        ip2 = str(random.randint(0, 10))
        ip3 = str(random.randint(0, 10))
        url = 'http://' + ip0 + '.' + ip1 + '.'+ ip2 + '.'+ ip3
        f.write(str(i) + "," + url + "\n")
        i += 1
    size = os.path.getsize(f_name)
    size = (int(size/(1000*1000))/10)*10
    print size
    os.rename(f_name, f_name +"_" + str(size))

    f.close()   
    
#print max_lines
def genURL(n_urls, f_name):
    f = open(f_name, "w");
    i = 0
    while(i < n_urls):
        ip0 = str(random.randint(0, 10))
        ip1 = str(random.randint(0, 10))
        ip2 = str(random.randint(0, 10))
        ip3 = str(random.randint(0, 10))
        url = 'http://' + ip0 + '.' + ip1 + '.'+ ip2 + '.'+ ip3

        f.write(url + "," + str(random.randint(0, 100))  + "\n")
        i += 1

    size = os.path.getsize(f_name)
    size = (int(size/(1000*1000))/10)*10
    print size
    os.rename(f_name, f_name +"_" + str(size))

    f.close()


if __name__ == "__main__":   
    n_users = 90000000 
    n_urls = 10000000
    f_users = "users.txt"
    f_urls = "urls.txt"
    genUsers(n_users, f_users)
    genURL(n_urls,f_urls)
    

