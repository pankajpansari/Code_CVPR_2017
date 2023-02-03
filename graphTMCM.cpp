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

#define INFTY 10000000
#define NLABEL_MAX 20
#define NCLIQUE_MAX 100
#define NVAR_MAX 200
#define ESTIMATED_NODES 9*1000
#define ESTIMATED_EDGES 5*10000

using namespace std;

const int debug_level = 1;
const int write_labeling_flag = 1;

/*This function computes the energy of a given labeling for a given instance of inputParameters*/
double compute_energy(const inputParameters &newInput, vector<int> labeling){

	const int nvar = newInput.nvar;
	const double M = newInput.M;
	const int m = newInput.m;
	const int nclique = newInput.nclique;
	const vector<double> distance_func = newInput.distance_func;
	const vector< vector<double> > unary_potentials = newInput.unary_potentials;
	const vector<double> clique_weight = newInput.clique_weight;
	const vector< vector<int> > clique_members = newInput.clique_members; 
	
	double unary_energy = 0;
	double clique_energy = 0;
	double total_energy = 0;
	double clique_cost;
	double normalized_clique_energy = 0;
	int clique_var_num;
	int m_clique;
	int clique_size;

	for(int i = 0; i < nvar; i++){
		unary_energy = unary_energy + unary_potentials[i][labeling[i]];
		if(debug_level >= 2){
			cout << "Unary for variable " << i << " : " << unary_potentials[i][labeling[i]] << endl;
		}
	}

	for(int j = 0; j < nclique; j++){
		vector<int> labels_current_clique;
		for(int k = 0, max = (int) clique_members[j].size(); k < max; k++){
			clique_var_num = clique_members[j][k];
			labels_current_clique.push_back(labeling[clique_var_num]);
		}
		sort(labels_current_clique.begin(), labels_current_clique.end());
		clique_size = (int) clique_members[j].size();
		m_clique = min((int) floor(clique_size/2), m);
		for(int m_count = 0; m_count < m_clique; m_count++){
			clique_cost = clique_weight[j]*min(distance_func[labels_current_clique[clique_size - 1 - m_count] - labels_current_clique[m_count]], M);
			if(debug_level >= 2){
				cout << "Clique weight: " << clique_weight[j] << endl;
				cout << "Truncated distance: " << min(distance_func[labels_current_clique[clique_size - 1 - m_count] - labels_current_clique[m_count]], M) << endl;
				cout << "Clique cost: " << clique_cost << endl;
			}
			clique_energy = clique_energy + clique_cost;	
			normalized_clique_energy += distance_func[labels_current_clique[clique_size - 1 - m_count] - labels_current_clique[m_count]];
		}		
	}
	total_energy = unary_energy + clique_energy;
	if(debug_level >= 2){
		cout << "Unary energy: " << unary_energy << endl;
		cout << "Clique energy: " << clique_energy << endl;
		cout << "Total energy: " << total_energy << endl;
	}

	return total_energy;
}

/*This function returns the optimum labeling for the MRF when each variable either retains its old label or takes up a label 
 * in the given interval.*/
vector<int> find_best_range_expansion(const inputParameters &newInput, vector<int> current_labeling, int range_start, int range_end){

	typedef Graph<double,double,double> GraphType;
	GraphType *g = new GraphType(/*estimated # of nodes*/ ESTIMATED_NODES, /*estimated # of edges*/ ESTIMATED_EDGES);

	const int nvar = newInput.nvar;
	const int nlabel = newInput.nlabel;
	const double M = newInput.M;
	const int m = newInput.m;
	const int nclique = newInput.nclique;
	const int distance_type = newInput.distance_type;
	const vector<double> distance_func = newInput.distance_func;
	const vector< vector<double> > unary_potentials = newInput.unary_potentials;
	const vector<double> clique_weight = newInput.clique_weight;
	const vector< vector<int> > clique_members = newInput.clique_members; 
	cout << "Range: " << range_start + 1 << " - " << range_end + 1<< endl;
	assert(range_start >= 0 && range_start < nlabel);
	assert(range_end <= nlabel && range_end >= range_start);
	
	vector<int> node_id_list;
	
	int original_label = 0;
	int L = range_end - range_start + 1;

	//add nodes & edges for unary potentials
	for(int i = 0; i < nvar; i++){
		for(int j = 0; j < L; j++){
			//j denotes label within the interval
			original_label = j + range_start;
			// if there is only one variable in the range
			if(j == 0 && j == L -1){
				node_id_list.push_back((int)g -> add_node());
				g -> add_tweights(node_id_list[i*L + j], unary_potentials[i][current_labeling[i]], unary_potentials[i][original_label]);
			}
			// if node is connected to source
			else if(j == 0){
				node_id_list.push_back((int)g -> add_node());
				g -> add_tweights(node_id_list[i*L + j], unary_potentials[i][current_labeling[i]], 0);
			}
			// if node is connected to sink
			else if(j == L - 1){
				node_id_list.push_back((int)g -> add_node());
				g -> add_tweights(node_id_list[i*L + j], 0, unary_potentials[i][original_label]);
				g -> add_edge(node_id_list[i*L + j - 1], node_id_list[i*L + j], unary_potentials[i][original_label - 1], numeric_limits<double>::infinity());
			}
			// for intermediate nodes
			else{
				node_id_list.push_back((int)g -> add_node());
				g -> add_edge(node_id_list[i*L + j - 1], node_id_list[i*L + j], unary_potentials[i][original_label - 1], numeric_limits<double>::infinity());				
			}
		}
	}			

	assert("Unary graph: Number of nodes does not match the calculation" &&  g->get_node_num() == nvar*L);
	assert("Unary graph: Number of arcs does not match the calculation" &&  g->get_arc_num() == nvar*(L-1)*2);

	//add nodes for higher-order potentials
	int u_node_id;
	int w_node_id;
	double r;
		
	if(distance_type == 1){
		for(int current_clique = 0; current_clique < nclique; current_clique++){
			int m_clique = min((int) floor(clique_members[current_clique].size()/2), m);
			for(int i = 1; i < L; i++){
				r = clique_weight[current_clique]*1;
				u_node_id = int(g -> add_node());
				w_node_id = int(g -> add_node());

				for(int k = 0, max = clique_members[current_clique].size(); k < max; k++){
					// if the k-th variable is included in the current clique
					int clique_var_num = (int) clique_members[current_clique][k];
					g -> add_edge(u_node_id, node_id_list[clique_var_num*L + i], r, 0);
					g -> add_edge(node_id_list[clique_var_num*L + i], w_node_id, r, 0);
				}			
				g -> add_edge(w_node_id, u_node_id, m_clique*r, 0);
			}
		}
	}

	else if(distance_type == 2){
		for(int current_clique = 0; current_clique < nclique; current_clique++){
			int m_clique = min((int) floor(clique_members[current_clique].size()/2), m);
			for(int i = 0; i < L; i++){
				for(int j = i; j < L; j++){
					// calculate the value of edge_weight r for this pair of label
					if(i > 0 || j>0){
						if(i == j){
							r = clique_weight[current_clique]*1;
						}
						else{
							r = clique_weight[current_clique]*2;
						}
					// add egdes to/from u and w node for this pair of label
						u_node_id = int(g -> add_node());
						w_node_id = int(g -> add_node());
						for(int k = 0, max = clique_members[current_clique].size(); k < max; k++){
							
							// if the k-th variable is included in the current clique
							int clique_var_num = clique_members[current_clique][k];
							g -> add_edge(u_node_id, node_id_list[clique_var_num*L + i], r, 0);
							g -> add_edge(node_id_list[clique_var_num*L + j], w_node_id, r, 0);							

						}			
						g -> add_edge(w_node_id, u_node_id, m_clique*r, 0);
					}
				}
			}
		}
	}

	//add overestimation graph
	double A, B;
	int y_node_id, z_node_id;
	double flow_constant = 0;
	
	for(int current_clique = 0; current_clique < nclique; current_clique++){

		int m_clique = min((int) floor(clique_members[current_clique].size()/2), m);

		y_node_id = int(g -> add_node());
		z_node_id = int(g -> add_node());
		vector<int> labels_current_clique;
		int label_count = 0;
		int clique_var_num = 0;

		for(int k = 0, max = clique_members[current_clique].size(); k < max; k++){
			clique_var_num = clique_members[current_clique][k];
			labels_current_clique.push_back(current_labeling[clique_var_num]);
			label_count = label_count + 1;		
		}

		sort(labels_current_clique.begin(), labels_current_clique.end());

		double truncated_sum = 0;
		for(int i = 0; i < m_clique; i++){
			truncated_sum = truncated_sum + min(distance_func[labels_current_clique[label_count - 1 -i] - labels_current_clique[i]], M);
		}
		
		A = clique_weight[current_clique]*M;
		B = clique_weight[current_clique]*(m_clique*M - truncated_sum);

		// for each variable in the clique, add node among Y, Z & first label node
		for(int k = 0, max = clique_members[current_clique].size(); k < max; k++){
			int clique_var_num = clique_members[current_clique][k];
			g -> add_edge(y_node_id, node_id_list[clique_var_num*L], A, 0);
			g -> add_edge(node_id_list[clique_var_num*L], z_node_id, B, 0);			
		}
		
		g -> add_tweights(y_node_id, m_clique*A, 0);
		g -> add_tweights(z_node_id, 0, B);
		flow_constant = flow_constant + B;
	
	}

	clock_t tStart = clock();
	double flow = g -> maxflow();
	clock_t tEnd = clock();
	
	if(debug_level >= 1){
		cout << "# nodes: " << g->get_node_num() << endl;
		cout << "# arcs: " << g->get_arc_num() << endl;
		cout << "Time for max-flow: " << (double)(tEnd-tStart)/(CLOCKS_PER_SEC) << "s" << endl;
	}
	if(debug_level >= 2){
		cout << "After over-estimation graph" << endl;	
		cout << "Max flow value: " << flow << endl;
		cout << "Constant: " << flow_constant << endl;
	}
	vector<int> new_labeling;

	int flag = 0;	// this flag to verify that the labeling assigned is valid	
	for(int i = 0; i < nvar; i++){
		flag = 0;
		for(int j = 0; j < L; j++){
			original_label = j + range_start;
			if(j == 0){
				if(g-> what_segment(node_id_list[i*L + j]) == GraphType::SINK){
					assert("Invalid multiple labeling" && flag == 0);
					new_labeling.push_back(current_labeling[i]);
					if(debug_level >= 2){
						cout << "Variable: " << i << " label: " << current_labeling[i] << endl;		
					}
					flag = 1;			
					}
			}
			if(j == L - 1){
				if(g-> what_segment(node_id_list[i*L + j]) == GraphType::SOURCE){
					assert("Invalid multiple labeling" && flag == 0);
					new_labeling.push_back(original_label);
					if(debug_level >= 2){
						cout << "Variable: " << i << " label: " << original_label << endl;		
					}
					flag = 1;
				}
			}
			else if(g-> what_segment(node_id_list[i*L + j]) == GraphType::SOURCE && g-> what_segment(node_id_list[i*L + j + 1]) == GraphType::SINK){
					assert("Invalid multiple labeling" && flag == 0);
					new_labeling.push_back(original_label);
					if(debug_level >= 2){
						cout << "Variable: " << i << " label: " << original_label << endl;		
					}
					flag = 1;
			}
		}
		assert("Variable not assigned any label" && flag == 1);
	}
	delete g;
	return new_labeling;
}

/*This function returns the fraction of variables which take up the majority label.
  It can be used to ensure that a particular clique weight value is neither too large or small.*/
double get_majority_fraction(vector<int> current_labeling){

	int countCurrent = 0, countMode = 0, current_num = 0, mode = 0;

	sort(current_labeling.begin(), current_labeling.end());

	for(int s: current_labeling){
		if(s == current_num){
			countCurrent += 1;
		}
		else{
			if(countCurrent > countMode){
				countMode = countCurrent;
				mode = current_num;	
			}

			current_num = s;
			countCurrent = 1;
		}
	}

	if(countCurrent > countMode){
		countMode = countCurrent;
		mode = current_num;	
	}

	return (double) countMode/(double) current_labeling.size();
}

/*This function returns the fraction of variables which take up the label corresponding to their minimum unary value.
  It can be used to ensure that a particular clique weight value is neither too large or small.*/
double get_min_unary_fraction(vector<int> current_labeling, vector< vector<double> > unary_potentials){
	int count_min_unary = 0;

	for(int i = 0, max = current_labeling.size(); i < max; i++){
		if(unary_potentials[i][current_labeling[i]] == *min_element(unary_potentials[i].begin(), unary_potentials[i].end()))
			count_min_unary += 1;
	}

	return (double) count_min_unary/(double) current_labeling.size();
}
			
/*This function takes a labeling and uses various measures to indicate suitability of the given labeling.
  It can be used to ensure that the parameters are set in such a way that most variables do not take the majority label
  or the label of minimum unary value.*/
void measure_labeling_quality(vector<int> current_labeling, vector< vector<double> > unary_potentials){

	double fracMajor = get_majority_fraction(current_labeling);
	double fracMinUnary = get_min_unary_fraction(current_labeling, unary_potentials);
	cout << "Fraction not majority: " << 1 - fracMajor << endl;
	cout << "Fraction not min unary: " << 1 - fracMinUnary << endl;	
}

/* This function iterates through intervals of consequtive labels of a given length, moving to or retaining the labeling of lowest local minimum energy at each iteration.
   The final labeling is stored in the given filename.*/ 
void make_moves(const inputParameters &newInput, const int interval_length, const string filename = "final_labeling.txt"){
	const int nvar = newInput.nvar;
	const int nlabel = newInput.nlabel;
	const double M = newInput.M;
	const int m = newInput.m;
	const vector<double> distance_func = newInput.distance_func;
	const vector< vector<double> > unary_potentials = newInput.unary_potentials;
	const vector<double> clique_weight = newInput.clique_weight;
	const vector< vector<int> > clique_members = newInput.clique_members; 
	int L = interval_length;

	int range_start;
	int range_end;
	vector<int> current_labeling(nvar);
	vector<int> possible_current_labeling;
	double prev_energy = numeric_limits<double>::infinity();
	double current_energy = numeric_limits<double>::infinity();
	int flag = 1;

	for(int i = 0; i < nvar; i++) {
		current_labeling[i] = 0;
	}
	
	for(int i = 1; i < 100; i++){
		cout << '-';
	}

	cout << endl << endl;
	cout << "Range Expansion - Initialization" << endl;
	current_energy = compute_energy(newInput, current_labeling);
	cout << "Current energy: " << current_energy << endl;

	prev_energy = current_energy;
	range_start = 0;
	range_end = range_start + L - 1;

	clock_t tStart = clock();
	while(flag == 1){
		flag = 0;
		for(int i = 0; i <= nlabel - L; i++){
			prev_energy = current_energy;
			range_start = i;
			range_end = range_start + L - 1;
			cout << endl << endl;
			
			clock_t iterStart = clock();
			
			possible_current_labeling = find_best_range_expansion(newInput, current_labeling, range_start, range_end);						
			
			cout << "Time for iteration: " << (double)(clock() - iterStart)/CLOCKS_PER_SEC << endl;

			current_energy = compute_energy(newInput, possible_current_labeling);

			assert("Energy after a range expansion iteration cannot increase" && current_energy <= prev_energy);
			if(current_energy < prev_energy){
				flag = 1;
				for(int t = 0; t < nvar; t++){
					current_labeling[t] = possible_current_labeling[t];
				}
			}		

			cout << "Current energy: " << current_energy << endl;
			if(write_labeling_flag == 2)
				write_labeling(current_labeling, "current_labeling.txt");
		}	

	}

	double execution_time = (double)(clock() - tStart)/CLOCKS_PER_SEC;

	cout << "Range Expansion - Completion" << endl;
	double final_energy = compute_energy(newInput, current_labeling);
	cout << endl << "Total execution time for range expansion: " << execution_time << "s" << endl;

	if(write_labeling_flag >= 1){
		string labeling_file = filename.substr(0, filename.size() - 4) + "L" + to_string(L) + + "_m" + to_string(m) + "_M" + to_string(int(M)) + "_wc" + to_string(int(clique_weight[0])) + "_labeling.txt"; 
		write_labeling(current_labeling, labeling_file);
	}
		
	
	measure_labeling_quality(current_labeling, unary_potentials);

}

/*This function executes range expansion algorithm for the given unary_num instance of a synthetic dataset and for the given parameter settings
  of the algorithm (interval_length) and the TMCM model (truncation_factor, weight, m).*/
void run_synthetic_instance(int distance_type, int unary_num, int truncation_factor, int interval_length, double weight, int m){

	/* verify that the arguments are valid */
	assert(distance_type == 1 || distance_type == 2); // 1 for linear, 2 for quadratic
	assert(unary_num >= 0 && unary_num <= 100); //100 instances of unaries present
	assert(weight >= 0);
	assert(m >= 1 && m <= 10); //since 20 labels are present
	assert(floor(interval_length) == interval_length); //interval_length should be an integer	

	if(distance_type == 1)
		assert(truncation_factor >= 0 && truncation_factor <=20);
	else
		assert(truncation_factor >=0 && truncation_factor <= 400);

	inputParameters synthetic_instance;	

	synthetic_instance = generate_synthetic_input(truncation_factor, m, weight, unary_num, distance_type);

	cout << "Static case" << endl << endl;

	make_moves(synthetic_instance, interval_length);
}

/*This function takes a specific configuration file (filename), model parameters and performs range expansion.*/
void run_config_instance(const string filename, int interval_len, int m, double weight, int truncation){

	inputParameters newInput;	
	newInput = read_file(filename);
	newInput.m = m;
	for(int i = 0, max = newInput.clique_weight.size(); i < max; i++)
		newInput.clique_weight[i] = weight*newInput.clique_weight[i];
	newInput.M = truncation;
	make_moves(newInput, interval_len, filename);
}

