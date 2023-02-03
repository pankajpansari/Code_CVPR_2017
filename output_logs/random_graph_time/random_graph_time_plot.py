#vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import matplotlib.pyplot as plt
import numpy as np
import re
import sys, getopt

def extract_time(filename, static_time, dynamic_time, percent_mod):

    f = open(filename, 'r')
    range_midpoint = []
    format_string = iter(['ro-', 'g^-', 'bs-', 'yp-', 'ch-', 'k*-'])
    label_list = iter(['Iteration 1', 'Iteration 2', 'Iteration 3', 'Iteration 4', 'Iteration 5', 'Iteration 6'])

    for text in f:
        if 'modification:' in text:
            match = re.search(r'/d+', text)
            print match
            #s = int(match.group())
            #percent_mod.append(s)

        if 'Static maxflow time: ' in text:
            match = re.search(r'\d+\.+\d+', text)
            s = float(match.group())
            static_time.append(s)

        if 'Dynamic maxflow time: ' in text:
            match = re.search(r'\d+\.\d+', text);
            s = float(match.group())
            dynamic_time.append(s)

  
    f.close()
   
def plot_time(time_list, plot_style):

    plt.plot(time_list, plot_style)
    plt.axis([0, len(time_list), 0, 1.1*max(time_list)])
    plt.legend()
    plt.xlabel('Number of iteration')
    plt.ylabel('Time (s)')




def main():
    
    filename = '/home/pankaj/Max_of_convex_code_new/Code/random_graph_time.txt' 
    static_time = []
    dynamic_time = []
    percent_mod = []
    extract_time(filename, static_time, dynamic_time, percent_mod)

    ratio_time = []

    for i in range(len(static_time)):
        ratio_time.append(dynamic_time[i]/static_time[i])
     
    percent_mod = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]
    plt.plot(percent_mod, ratio_time, 'bo-')
    plt.xlabel('% arc modifications')
    plt.ylabel('Dynamic_time/Static_time')
    plt.title('Behavior of the dynamic algorithm')
    #plt.text('#nodes = 10^5 #arcs = 16 * 10^5')
    plt.show()


if __name__ == '__main__':
    main()
