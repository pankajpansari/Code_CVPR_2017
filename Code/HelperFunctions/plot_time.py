import matplotlib.pyplot as plt
import numpy as np
import re

f = open('iteration_time_orig_quad_M100w5m3.txt', 'r')
time_list = []
for line in f:
	print line
	time_num = float(line)
	time_list.append(float(line))

f2 = open('iteration_time_orig_quad_M100w5m3.txt', 'r')
time_list2 = []
for line in f2:
	print line
	time_num = float(line)
	time_list2.append(float(line))

time_diff = time_list - time_list2
plt.plot(time_diff)
#plt.plot(time_list2)
plt.show()
#for line in f:
#	print line





