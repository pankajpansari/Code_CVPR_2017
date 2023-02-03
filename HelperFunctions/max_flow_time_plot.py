import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import numpy as np
import re
import sys, getopt
import os
from itertools import cycle
from matplotlib.pyplot import cm

def extract_time(filename, maxflow_time, iter_time, energy_list):

    f = open(filename, 'r')
    range_midpoint = []
    format_string = iter(['ro-', 'g^-', 'bs-', 'yp-', 'ch-', 'k*-'])
    label_list = iter(['Iteration 1', 'Iteration 2', 'Iteration 3', 'Iteration 4', 'Iteration 5', 'Iteration 6'])
    max_time = 0
    max_iter_time = 0

    for text in f:
        if 'Range:' in text:
            match = re.search(r'\d+\s-\s\d+', text)
            s = match.group()
            midpoint = (int(s.split()[0]) + int(s.split()[2])) / 2
            if midpoint not in range_midpoint:
                range_midpoint.append(midpoint)

        if 'Time for max-flow: ' in text:
            match = re.search(r'\d+\.*\d*', text)
            s = float(match.group())
            maxflow_time.append(s)

        if 'Time for iteration: ' in text:
            match = re.search(r'\d+\.*\d*', text);
            s = float(match.group())
            iter_time.append(s)

        if 'Current energy: ' in text:
            match = re.search(r'\d+', text)
            s = int(match.group())
            energy_list.append(s) 
   
    f.close()

  
def running_sum(time_list):

    time_sum_list = []

    for i in range(0, len(time_list)):
        time_sum = 0
        for j in range(0, i + 1):
            time_sum += time_list[j]
        time_sum_list.append(time_sum)

    for i in range(0, len(time_list)):
        time_list[i] = time_sum_list[i]

def mean(value_list):

    sumVal = 0
    for item in value_list:
        sumVal += item
    return sumVal/len(value_list)

def stretch_list(value_list, new_len):

    current_len = len(value_list)
    while len(value_list) < new_len:
        value_list.append(value_list[current_len - 1])
    return value_list

def average_list(list_of_list):

    mean_list = []
    num_list = len(list_of_list)
    for item in list_of_list:
        if len(item) != len(list_of_list[0]):
            print 'List len should be same for averaging'
    for i in range(0, len(list_of_list[0])):
        sum_i = 0
        for item in list_of_list:
            sum_i += item[i]
        mean_list.append(sum_i/num_list)
    return mean_list

def extract_time_cooc(filename, time_list, energy_list):
    f = open(filename, 'r')

    cumulative_time = []
    for text in f:
        if 'Energy: ' in text and 'COOC' not in text:
            match = re.search(r'\d+', text)
            s = int(match.group())
            energy_list.append(s)

        if 'Time: ' in text and 'COOC' not in text:
            match = re.search(r'\d+\.*\d*', text) 
            s = float(match.group())
            cumulative_time.append(s)

    for i in range(0, len(cumulative_time)):
        if i == 0:
            time_list.append(cumulative_time[i])
        else:
            time_list.append(cumulative_time[i] - cumulative_time[i - 1])

    f.close() 

def extract_time_hier(filename, time_list, energy_list):
    f = open(filename, 'r')

    for text in f:
        if 'Energy:' in text and 'Time:' in text:
            match = re.search(r'Total Energy:\d+', text)
            s = match.group()
            energy_list.append(int(s[13:]))

            match = re.search(r'Time:\d+\.*\d*', text) 
            s = match.group()
            time_list.append(float(s[5:]))

    f.close() 

 
#def plot_time_quadratic():
#
#    file_list_full = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/quadratic')
#    interval_length_list = [4, 6]
#    color = ['b', 'k', 'r', 'g', 'y', 'm', 'c', 'b']
#    plot_handles_list = []
#
#    max_energy= 0
#    max_time = 0
#    min_energy = 100000000
#
## plot energy vs time for TMCM 
#    for interval_length in interval_length_list:
#        file_list = []
#
#        for filename in file_list_full:
#            match = re.search(r'quadratic_M25_.*L%d_.*' % interval_length, filename)
#            if match:
#                file_list.append(match.group())
#        lines = ["", "--", "-.", ":"]
#        current_color = color.pop()
#        max_len = 0
#        avg_list = []
#        energy_list = []
#
#        for filename in file_list:
#            filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/quadratic/', filename)
#            maxflow_time = []
#            iter_time = []
#            energy = []
#            extract_time(filename, maxflow_time, iter_time, energy)
#            energy = energy[1:]
#            if len(maxflow_time) > max_len:
#                max_len = len(maxflow_time)
#            avg_list.append(mean(maxflow_time))
#            energy_list.append(energy)
#
#        for i in range(0, len(energy_list)):
#            energy_list[i] = stretch_list(energy_list[i], max_len)
#
#        for i in range(0, len(energy_list)):
#            if len(energy_list[i]) != max_len:
#                    print 'Lists differ in sizes'
#
#        global_avg = mean(avg_list)
#        average_energy = average_list(energy_list)
#        time_list = []
#
#        for i in range(0, max_len):
#            time_list.append((i+1)*global_avg)
#        
#    #    j = 0
#    #    while j*global_avg < time_limit:
#    #        j += 1
#
#        plt.plot(time_list, average_energy, c = current_color, label = 'L = ' + str(interval_length), linewidth = 2)
#        if min_energy > min(average_energy):
#            min_energy = min(average_energy)
#        if max_energy < max(average_energy):
#            max_energy = max(average_energy)
#
#
##    plt.plot(time_list, mean_energy, 'ro', label = 'Hierarchical')
#    plt.yticks(np.arange(342500, 347500, 1000))
#    plt.tick_params(axis='both', which='major', labelsize= 20)
#    plt.text(2500, 346300,'M = 25 m = 1 weight = 3', fontsize = 25)
#    plt.legend(fontsize = 20)
##    plt.axis([0, max_len*global_avg, 0.99*min_energy, 1.01*max_energy])
#    plt.xlabel('Time (in s)', fontsize = 25)
#    plt.ylabel('Energy', fontsize = 25)
#    
#    #plt.title('M = 225 m = 1 weight = 3')
#    plt.show()

def plot_time_quadratic(ax, M, interval_length_list, weight):

    file_list_full = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/quadratic')
    color = ['b', 'k', 'r', 'g', 'y', 'm', 'c', 'b']
    plot_handles_list = []

    max_energy= 0
    max_time = 0
    min_energy = 100000000
#    print 'M = %d \n' % M 

# plot energy vs time for TMCM 
    for interval_length in interval_length_list:
        file_list = []
        iter_count = 0
        for filename in file_list_full:
            match = re.search(r'quadratic_M' + str(M) + '_.*L%d_.*' % interval_length + 'w%d_.*' % weight, filename)
            if match:
                #print match.group()
                iter_count += 1
                file_list.append(match.group())
#        print 'Number of iter = %d \n' % iter_count
        lines = ["", "--", "-.", ":"]
        current_color = color.pop()
        max_len = 0
        avg_list = []
        energy_list = []

        for filename in file_list:
            filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/quadratic/', filename)
            maxflow_time = []
            iter_time = []
            energy = []
            extract_time(filename, maxflow_time, iter_time, energy)
            energy = energy[1:]
            if len(maxflow_time) > max_len:
                max_len = len(maxflow_time)
            avg_list.append(mean(maxflow_time))
            energy_list.append(energy)

        for i in range(0, len(energy_list)):
            energy_list[i] = stretch_list(energy_list[i], max_len)

        for i in range(0, len(energy_list)):
            if len(energy_list[i]) != max_len:
                    print 'Lists differ in sizes'

        global_avg = mean(avg_list)
        average_energy = average_list(energy_list)
        time_list = []

        for i in range(0, max_len):
            time_list.append((i+1)*global_avg)
        
    #    j = 0
    #    while j*global_avg < time_limit:
    #        j += 1
        myInt = 10000
        norm_energy = [x / float(myInt) for x in average_energy]
        ax.plot(time_list, norm_energy, c = current_color, label = 'L = ' + str(interval_length), linewidth = 3)
        ax.tick_params(axis='both', which='major', labelsize= 25)
        ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize = 20) 

        if M == 100:
            ax.set_ylabel('Energy (X $10^4$)', fontsize = 30)
  # 

def plot_time_linear(ax, M, interval_length_list, weight, cooc_flag):

    file_list_full = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/linear')
    color = ['b', 'k', 'r', 'g', 'y', 'm', 'c', 'b']
    plot_handles_list = []

    max_energy= 0
    min_energy = 100000000
    time_limit = 50

   # print 'M = %d \n' % M
# plot energy vs time for TMCM 
    for interval_length in interval_length_list:
        file_list = []

        iter_count = 0
        for filename in file_list_full:
            match = re.search(r'linear_M' + str(M) + '_.*L%d_.*' % interval_length + '.*w%d_.*' % weight, filename)
            if match:
                #print match.group()
                iter_count = iter_count + 1
                file_list.append(match.group())
       # print 'Number of iter = %d \n' % iter_count
        lines = ["", "--", "-.", ":"]
        current_color = color.pop()
        max_len = 0
        avg_list = []
        energy_list = []

        for filename in file_list:
            filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/linear/', filename)
            maxflow_time = []
            iter_time = []
            energy = []
            extract_time(filename, maxflow_time, iter_time, energy)
            energy = energy[1:]
            if len(maxflow_time) > max_len:
                max_len = len(maxflow_time)
            avg_list.append(mean(maxflow_time))
            energy_list.append(energy)

        for i in range(0, len(energy_list)):
            energy_list[i] = stretch_list(energy_list[i], max_len)

        for i in range(0, len(energy_list)):
            if len(energy_list[i]) != max_len:
                    print 'Lists differ in sizes'

        global_avg = mean(avg_list)
        average_energy = average_list(energy_list)
        time_list = []

        for i in range(0, max_len):
            time_list.append((i+1)*global_avg)
        
#        j = 0
#        while j*global_avg < time_limit:
#            j += 1
        myInt = 10000
        norm_energy = [x / float(myInt) for x in average_energy]
#        ax.plot(time_list[:j], norm_energy[:j], c = current_color, label = 'L = ' + str(interval_length), linewidth = 2)
        ax.plot(time_list, norm_energy, c = current_color, label = 'L = ' + str(interval_length), linewidth = 2)
        if min_energy > min(average_energy):
            min_energy = min(average_energy)
        if max_energy < max(average_energy):
            max_energy = max(average_energy)

# plot energy vs time for Cooccurence

    file_list_full = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/cooc_logs/')
    avg_list = []
    energy_list = []
    max_len = 0 

    for filename in file_list_full:
        iter_time = []
        energy = []
        match = re.search(r'linear_M' + str(M) + '.*_w%d.*' % weight, filename)
        if match:
            filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/cooc_logs/', filename)
            extract_time_cooc(filename, iter_time, energy)
            energy = energy[2:]
            avg_list.append(mean(iter_time))
            energy_list.append(energy)
            if len(energy_list) > max_len:
                max_len = len(energy_list)
                
    for i in range(0, len(energy_list)):
            energy_list[i] = stretch_list(energy_list[i], max_len)

    for i in range(0, len(energy_list)):
        if len(energy_list[i]) != max_len:
            print 'Lists differ in sizes'

    global_avg = mean(avg_list)
    average_energy = average_list(energy_list)
    time_list = []

    for i in range(0, max_len):
        time_list.append((i+1)*global_avg)

       
    norm_energy = [x / float(myInt) for x in average_energy]

    if cooc_flag == 1:
        ax.plot(time_list, norm_energy, 'k-', linewidth = 3)
        ax.plot(time_list[max_len -1], norm_energy[max_len - 1], 'ko', markersize = 10)

#stretch the plot
    max_len2 = max_len
    max_len = 7000
    for i in range(0, len(energy_list)):
            energy_list[i] = stretch_list(energy_list[i], max_len)

    for i in range(0, len(energy_list)):
        if len(energy_list[i]) != max_len:
            print 'Lists differ in sizes'

    global_avg = mean(avg_list)
    average_energy = average_list(energy_list)
    time_list = []

    for i in range(0, max_len):
        time_list.append((i+1)*global_avg)

    norm_energy = [x / float(myInt) for x in average_energy]
    if cooc_flag == 1:
        ax.plot(time_list[max_len2:], norm_energy[max_len2:], 'k:', label = 'Cooccurrence', linewidth = 3)

# plot energy vs time for hierarchical

    file_list_full = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/hier_logs/')
    time_list_list = []
    energy_list_list = []
    max_len = 200

    for filename in file_list_full:
        match = re.search(r'linear_M' + str(M) + '.*_w%d.*' % weight, filename)
        if match:
            filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/hier_logs/', filename)
           # print match.group()
            time_list = []
            energy_list = []
            extract_time_hier(filename, time_list, energy_list)
            time_list_list.append(time_list[0])
            energy_list_list.append(energy_list[0])

    mean_energy = []
    mean_energy.append(mean(energy_list_list))
    mean_time = mean(time_list_list); 

    mean_energy = stretch_list(mean_energy, max_len)
    time_list = []

    for i in range(0, max_len):
        time_list.append((i+1)*mean_time)

    norm_energy = [x / float(myInt) for x in mean_energy]

    ax.plot(time_list[0], norm_energy[0], 'ro', markersize = 10)
    
    ax.plot(time_list, norm_energy, 'r--', label = 'Parsimonious', linewidth = 3)
    ax.tick_params(axis='both', which='major', labelsize= 25)
    ax.legend(bbox_to_anchor=(1.02, 1), loc=2, borderaxespad=0, fontsize = 20)
    
    if M == 10:
        ax.set_ylabel('Energy ($X 10^4$)', fontsize = 30)

def main():

    weight_linear = 10 
    weight_quadratic = 5
    cooc_flag = 0 
    fig = plt.figure(figsize = (22, 11))
    ax1 = fig.add_subplot(311)
    ax2 = fig.add_subplot(312)
    ax3 = fig.add_subplot(313)

    M = 5
    interval_len_list = [4, 6]
    plot_time_linear(ax1, M, interval_len_list, weight_linear, cooc_flag)
    M = 10
    interval_len_list = [4, 6, 8, 10, 12]
    plot_time_linear(ax2, M, interval_len_list, weight_linear, cooc_flag)
    M = 15
    interval_len_list = [4, 6, 8, 10, 12, 14, 16]
    plot_time_linear(ax3, M, interval_len_list, weight_linear, cooc_flag)

    plt.xlabel('Time (in s)', fontsize = 30)

    ax1.set_xlim([0, 2000])
    ax2.set_xlim([0, 2000])
    ax3.set_xlim([0, 2000])

    start, end = ax1.get_ylim()
    ax1.yaxis.set_ticks(np.arange(start, end, 0.1))
    start, end = ax2.get_ylim()
    ax2.yaxis.set_ticks(np.arange(start, end, 0.1))
    start, end = ax3.get_ylim()
    ax3.yaxis.set_ticks(np.arange(start, end, 0.1))
#
#    ax1.text(200, 35.6, 'M = 25', fontsize = 20, weight = 'bold')
#    ax2.text(200, 35.6, 'M = 100', fontsize = 20, weight = 'bold')
#    ax3.text(200, 35.6, 'M = 225', fontsize = 20, weight = 'bold')

    if cooc_flag == 1:
        plt.savefig('linear_w' + str(weight_linear) + '_cooc.png', bbox_inches = 'tight')
    else:
        plt.savefig('linear_w' + str(weight_linear) + '.png', bbox_inches = 'tight')

    plt.show()
     
    fig = plt.figure(figsize = (22, 11))
    ax1 = fig.add_subplot(311)
    ax2 = fig.add_subplot(312)
    ax3 = fig.add_subplot(313)

    M = 25
    interval_len_list = [2, 4]
    plot_time_quadratic(ax1, M, interval_len_list, weight_quadratic)
    M = 100
    interval_len_list = [2, 4]
    plot_time_quadratic(ax2, M, interval_len_list, weight_quadratic)
    M = 225 
    interval_len_list = [2, 4]
    plot_time_quadratic(ax3, M, interval_len_list, weight_quadratic)

    plt.xlabel('Time (in s)', fontsize = 30)

    ax1.set_xlim([0, 400])
    ax2.set_xlim([0, 400])
    ax3.set_xlim([0, 400])

    start, end = ax1.get_ylim()
    ax1.yaxis.set_ticks(np.arange(start, end, 0.2))
    start, end = ax2.get_ylim()
    ax2.yaxis.set_ticks(np.arange(start, end, 0.2))
    start, end = ax3.get_ylim()
    ax3.yaxis.set_ticks(np.arange(start, end, 0.2))

#    ax1.text(200, 37.3, 'M = 25', fontsize = 20, weight = 'bold')
#    ax2.text(200, 37.3, 'M = 100', fontsize = 20, weight = 'bold')
#    ax3.text(200, 37.3, 'M = 225', fontsize = 20, weight = 'bold')

    plt.savefig('quadratic_w' + str(weight_quadratic) + '.png', bbox_inches = 'tight')
    plt.show()

       
if __name__ == '__main__': main()
