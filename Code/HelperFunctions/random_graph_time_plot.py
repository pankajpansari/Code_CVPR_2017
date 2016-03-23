#vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import matplotlib.pyplot as plt
import numpy as np
import re
import sys, getopt
import os, os.path

def extract_time(filename, ratio_time):

    f = open(filename, 'r')
    range_midpoint = []
    static_count = 0
    dynamic_count = 0
    static_time = []
    dynamic_time = []

    for text in f:
        if 'Static maxflow time: ' in text:
            match = re.search(r'\d+\.+\d+', text)
            s = float(match.group())
            static_time.append(s)
            #static_time.append(s)

        if 'Dynamic maxflow time: ' in text:
            match = re.search(r'\d+\.\d+', text);
            s = float(match.group())
            dynamic_time.append(s)
            #dynamic_time.append(s)

    for i in range(len(static_time)):
        ratio_time[i] = ratio_time[i] + dynamic_time[i]/static_time[i]
  
    f.close()
   
def plot_time(time_list, plot_style):

    plt.plot(time_list, plot_style)
    plt.axis([0, len(time_list), 0, 1.1*max(time_list)])
    plt.legend()
    plt.xlabel('Number of iteration')
    plt.ylabel('Time (s)')

def main():
    
    ratio_time = list(0.0 for i in range(0, 21))
    #percent_mod = list(0 for i in range(0, 21)) 

    path_name = '/home/pankaj/Max_of_convex_code_new/Code/output_logs/random_graph_time/trial/'
    file_list = os.listdir(path_name)
#    file_list = ['random_graph_time_0_81.txt', 'random_graph_time_4_10.txt']
    for file_name in file_list:
        full_file_name = path_name + file_name 
        extract_time(full_file_name, ratio_time)

    file_num = len(file_list)

    ratio_time = [x / file_num for x in ratio_time]

    for item in ratio_time:
        print item

    percent_mod = range(0,101,5)
    plt.plot(percent_mod, ratio_time, 'bo-')
    plt.xlabel('% arc modifications')
    plt.ylabel('Dynamic_time/Static_time')
    plt.title('Behavior of the dynamic algorithm averaged over 40 graphs')
    #plt.text('#nodes = 10^5 #arcs = 16 * 10^5')
    plt.show()

if __name__ == '__main__':
    main()
