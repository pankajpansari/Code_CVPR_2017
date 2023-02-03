#ifndef READ_INPUT_H
#define READ_INPUT_H

#include <fstream>
#include <iostream>
#include <string>
#include <math.h>
#include <time.h>
#include <algorithm>
#include <vector>
#include <assert.h>
#include <sstream>
#include <limits>
using namespace std;

struct inputParameters{
	int nvar;
	int nlabel;
	double M;
	int m;
	vector< vector<double> > unary_potentials;
	int distance_type;
	vector<double> distance_func;
	int nclique;
	vector< vector<int> > clique_members;
	vector<double> clique_weight;
	vector<int> clique_sizes;
};	

inputParameters read_file(const string& fileName);
inputParameters generate_synthetic_input(double M, int m, double clique_weight, int iteration_number, int distance_type);
inputParameters generate_synthetic_input_4connected(double M, int m, double clique_weight, int iteration_number, int distance_type);
void printInputParameter(inputParameters newInput);
inputParameters generate_synthetic_Ondra(double clique_weight, int iteration_number, int distance_type);
vector<int> read_labeling(string filename);
void write_labeling(vector<int> labeling, string filename);
	
#endif
