#include <fstream>
#include <iostream>
#include <string>
#include <math.h>
#include <cmath>
#include "graph.h"
#include <time.h>
#include <algorithm>
#include <vector>
#include <assert.h>
#include <sstream>
#include <limits>
#include <map>
#include <utility>
#include "readConfigFile.h"
#include "graphTMCM.h"

using namespace std;

int main(int argc, char* argv[]){

/*	if(argc < 7)
		cout << "Arguments: iteration_num distance_type truncation_factor interval_length weight m" << endl;
	int iteration_num = atoi(argv[1]);
	int distance_type = atoi(argv[2]);
	int truncation_factor = atoi(argv[3]);
	int interval_length = atoi(argv[4]);
	double weight = atoi(argv[5]);
	int m = atoi(argv[6]);

	inputParameters newInput = generate_synthetic_input(truncation_factor, m, weight, iteration_num, distance_type);

	string input_filename = "input_linear_M" + to_string(truncation_factor) + "_w" + to_string(int(weight)) + "_iter" + to_string(iteration_num) + ".txt"; 
	ofstream out("/home/pankaj/Max_of_convex_code_new/Code/" + input_filename);
//	ofstream out("/home/pankaj/Max_of_convex_code_new/Code/Baseline_code/matlab_codes/input_instance.txt");
//	ofstream out("./Baseline_code/matlabcodes/input_instance.txt");
	streambuf *coutbuf = cout.rdbuf();
	cout.rdbuf(out.rdbuf());

	printInputParameter(newInput); 

	cout.rdbuf(coutbuf);*/

//	test_synthetic(distance_type, iteration_num, truncation_factor, interval_length, weight, m); 

	// arguments in order - filename interval_length m clique_weight truncation
	run_config_instance(argv[1], atoi(argv[2]), atoi(argv[3]), atof(argv[4]), atof(argv[5]));

//	inputParameters newInput = read_file(argv[1]);
//	printInputParameter(newInput);
//	vector<int> labeling = read_labeling(argv[2]);
//	cout << "Energy: " << compute_energy(newInput, labeling) << endl;
//	test_instance("input_instance.txt");

	return 0;
}
