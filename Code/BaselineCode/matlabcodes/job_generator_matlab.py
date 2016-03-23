def bash_script():
    f = open('command_list.txt', 'w');
    distance_type = 1
    truncation_list = [5, 10, 15] 
    interval_len = 5
    weight = 10 
    m = 1

    for iteration_num in range(0, 10):
        for truncation_factor in truncation_list:
            command1 = "~/Max_of_convex_code_new/Code/p_generate_input_file " + str(iteration_num) + " " + str(distance_type) + " " + str(truncation_factor) + " " + str(interval_len) + " " + str(weight) + " " + str(m) + "\n"
            input_file = "../../input_linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            output_file = "../../output_logs/hier_logs/linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            command2 = 'matlab -nodisplay -nosplash -nojvm -r "wrapperParsimoniousHier(\'' + input_file + '\')" > ' + output_file + "\n"
#            print command1
#            print command2
            f.write(command1)
            f.write(command2)

    f.close()

def matlab_script_hier():
    f = open('hier_command_list_3.m', 'w');
    distance_type = 1
    truncation_list = [5, 10, 15] 
    interval_len = 5
    weight = 10 
    m = 1
    f.write('startup_all\n')
    f.write('compile_all\n')
    for iteration_num in range(20, 50):
        for truncation_factor in truncation_list:
            command1 = "system('~/Max_of_convex_code_new/Code/p_generate_input_file " + str(iteration_num) + " " + str(distance_type) + " " + str(truncation_factor) + " " + str(interval_len) + " " + str(weight) + " " + str(m) + "');\n"
            input_file = "../../input_linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            output_file = "../../output_logs/hier_logs/linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            command2 = "diary '" + output_file + "'\n"
            command3 = "wrapperParsimoniousHier('" + input_file + "');\n" 
            command4 = "diary off\n"
            f.write(command1)
            f.write(command2)
            f.write(command3)
            f.write(command4)

    f.close()

def matlab_script_cooc():
    f = open('cooc_command_list.m', 'w');
    distance_type = 1
    truncation_list = [5, 10, 15] 
    interval_len = 5
    weight = 10 
    m = 1
    f.write('startup_all\n')
    f.write('compile_all\n')
    for iteration_num in range(0, 50):
        for truncation_factor in truncation_list:
            #command1 = "system('~/Max_of_convex_code_new/Code/p_generate_input_file " + str(iteration_num) + " " + str(distance_type) + " " + str(truncation_factor) + " " + str(interval_len) + " " + str(weight) + " " + str(m) + "');\n"
            input_file = "../../input_linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            output_file = "../../output_logs/cooc_logs/linear_M" + str(truncation_factor) + "_w" + str(weight) + "_iter" + str(iteration_num) + ".txt"
            command2 = "diary '" + output_file + "'\n"
            command3 = "wrapperParsimoniousCOOC('" + input_file + "');\n" 
            command4 = "diary off\n"
            #f.write(command1)
            f.write(command2)
            f.write(command3)
            f.write(command4)

    f.close()


def main():
    matlab_script_cooc()


if __name__ == '__main__':
    main()

