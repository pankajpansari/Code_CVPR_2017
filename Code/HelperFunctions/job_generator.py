import os

def synthetic_experiments(distance, weight, m = 1):
    f = open('command_list.txt', 'w');
    path = '~/Max_of_convex_code_new/'

    if distance == 'linear':
        distance_type = 1
        truncation_list = [5, 10, 15] 
    elif distance == 'quadratic':
        distance_type = 2
        truncation_list = [25, 100, 225] 

   # truncation_list = [25, 100, 225] 

    for truncation_factor in truncation_list:
        for iteration_num in range(0, 50):
            if distance_type == 1:
                interval_len_list = range(4, truncation_factor + 3, 2)
            elif distance_type == 2:
                interval_len_list = [2, 4]
            for interval_len in interval_len_list:
                output_file = path + "Code/output_logs/synthetic_static/" + distance + "_M" + str(truncation_factor) + "_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
                command = path + "Code/p_static " + str(iteration_num) + " " + str(distance_type) + " " + str(truncation_factor) + " " + str(interval_len) + " " + str(weight) + " " + str(m) + " > " + output_file + "\n"
                f.write(command)
    #

    f.close()

def inpainting_experiments():
    f = open('command_list.txt', 'w');
    path = '~/Max_of_convex_code_new/'
    m_list = [3, 5]
    weight_penguin_list = [40]
    weight_house_list = [50]
    truncation_penguin_list = [40]
    truncation_house_list = [50]
    interval_len_list = [5, 10, 20]
    input_file_penguin = path + "Data/configFiles/input/confFileInpainting_penguin.txt"
    input_file_house = path + "Data/configFiles/input/confFileInpainting_house.txt"
    
# for penguin input
    for m in m_list:
        for weight_penguin in weight_penguin_list:
            for truncation in truncation_penguin_list: 
                for interval_len in interval_len_list:
                    output_file = path + "Code/output_logs/inpainting/penguin_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_penguin) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_penguin + " " + str(interval_len) + " " + str(m) + " " + str(weight_penguin) + " " + str(truncation) + " > " + output_file + "\n"
                    f.write(command)

# for house input
    for m in m_list:
        for weight_house in weight_house_list:
            for truncation in truncation_house_list: 
                for interval_len in interval_len_list:
                    output_file = path + "Code/output_logs/inpainting/house_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_house) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_house + " " + str(interval_len) + " " + str(m) + " " + str(weight_house) + " " + str(truncation) + " > " + output_file + "\n"
                    f.write(command)

   
    f.close()

def stereo_experiments():
    f = open('command_list.txt', 'w');
    path = '~/Max_of_convex_code_new/'
    #m_list = [1, 2, 5]
    m_list = [3]
    weight_teddy_list = [20]
    #weight_tsukuba_list = [10, 15, 20, 25, 30] 
    weight_tsukuba_list = [20] 
    weight_cone_list = [20]
    weight_venus_list = [20]
    #truncation_teddy_list = [1, 5, 10]
    truncation_teddy_list = [1]
    #truncation_tsukuba_list = [1, 5, 10]
    truncation_tsukuba_list = [5]
    truncation_cone_list = [5]
    truncation_venus_list = [5]

    input_file_teddy = path + "Data/configFiles/confFileStereo_teddy.txt"
    input_file_tsukuba = path + "Data/configFiles/confFileStereo_tsukuba.txt"
    input_file_cone = path + "Data/configFiles/confFileStereo_cone.txt"
    input_file_venus = path + "Data/configFiles/confFileStereo_venus.txt"

    existing_file_list = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/stereo/')
    print "hello"

# for teddy input
    for m in m_list:
        for weight_teddy in weight_teddy_list:
            for truncation in truncation_teddy_list: 
                for interval_len in [1, 3, 5]:
               # for interval_len in range(1, truncation + 5, 2):
                    output_file = path + "Code/output_logs/stereo/teddy_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_teddy) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_teddy + " " + str(interval_len) + " " + str(m) + " " + str(weight_teddy) + " " + str(truncation) + " > " + output_file + "\n"
#                    f.write(command)

# for tsukuba input
    for m in m_list:
        for weight_tsukuba in weight_tsukuba_list:
            for truncation in truncation_tsukuba_list:
                for interval_len in [6]:
               # for interval_len in range(2, truncation + 4, 2):
                    output_file = path + "Code/output_logs/stereo/tsukuba_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_tsukuba) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_tsukuba + " " + str(interval_len) + " " + str(m) + " " + str(weight_tsukuba) + " " + str(truncation) + " > " + output_file + "\n"
                    f.write(command)
# for cone input
    for m in m_list:
        for weight_cone in weight_cone_list:
            for truncation in truncation_cone_list:
                for interval_len in [2, 4, 6]:
               # for interval_len in range(2, truncation + 4, 2):
                    output_file = path + "Code/output_logs/stereo/cone_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_cone) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_cone + " " + str(interval_len) + " " + str(m) + " " + str(weight_cone) + " " + str(truncation) + " > " + output_file + "\n"
#                    f.write(command)

# for venus input
    for m in m_list:
        for weight_venus in weight_venus_list:
            for truncation in truncation_venus_list:
                for interval_len in [2, 4, 6]:
                    output_file = path + "Code/output_logs/stereo/venus_L" + str(interval_len) + "_m" + str(m) + "_w" + str(weight_venus) + "_M" + str(truncation) + ".txt"
                    command = path + "Code/p_inpainting_batch " + input_file_venus + " " + str(interval_len) + " " + str(m) + " " + str(weight_venus) + " " + str(truncation) + " > " + output_file + "\n"
#                    f.write(command)

    f.close()


def main():
#    inpainting_experiments() 
   # synthetic_experiments('linear', 10, 1)
 #   synthetic_experiments('quadratic', 5, 1)
     stereo_experiments()

if __name__ == '__main__':
    main()
