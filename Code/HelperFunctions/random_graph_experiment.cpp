#include <stdio.h>
#include "graph.h"
#include <iostream>
#include <random>
#include <fstream>
#include <string>
#include <map>
using namespace std;
#define ARC_CAP_MAX 100
int debug_level = 0;
int num_nodes = 1000;
int num_edges = 16000;


typedef Graph<int,int,int> GraphType;

vector<int> node_id_list;
map< pair<int, int>, double> arc_capacity_list;
map< pair<int, int>, GraphType::arc_id> arc_pointer_list;
const int node_s = -1, node_t = -2;
long int arc_count = 0;
GraphType::arc_id current_arc;

void reset_graph(GraphType *g){
	if(debug_level >=2)
		cout << "Resetting graph, initializing node_id list and capacity and pointer maps" << endl;
	g->reset();
	node_id_list.clear();
	arc_capacity_list.clear();
	arc_pointer_list.clear();	
	current_arc = g -> get_first_arc();
}

void edge_add(GraphType *g, int node_i, int node_j, double weight_ij, double weight_ji){
	g -> add_edge(node_i, node_j, weight_ij, weight_ji);
}

void tweights_add(GraphType *g, int node_i, double weight_si, double weight_it){
	g -> add_tweights(node_i, weight_si, weight_it);
}

void create_new_graph(GraphType *g, int num_nodes, int num_edges, int gen_seed){
	random_device rd;
	mt19937 gen;
	gen.seed(gen_seed);
	srand(22);
	uniform_int_distribution<> node_id_rand(0, num_nodes - 1); 
	uniform_int_distribution<> arc_cap_rand(1, ARC_CAP_MAX);

	//add nodes to original graph g
	for(int i = 0; i < num_nodes; i++){
		g -> add_node();
		if(debug_level >= 2)
			cout << "Added node " << i+1 << endl;
	}
	
	assert(g->get_node_num() == num_nodes);
/*
	random_device rd;
	mt19937 gen(rd());
	uniform_int_distribution<> node_id_rand(0, num_nodes - 1); 
	uniform_int_distribution<> arc_cap_rand(1, ARC_CAP_MAX);*/

	int node_u, node_v;
	double sweight, tweight, arc_cap;

	for(int i = 0; i < num_nodes; i++){
		node_u = node_id_rand(gen);	
		sweight = arc_cap_rand(gen); 
		tweight = arc_cap_rand(gen);
		if(debug_level >= 2)
			cout << "Added tweight for node " << node_u << "scap: " << sweight << "tcap: " << tweight << endl;
		g->add_tweights(node_u, sweight, tweight); 
	}

	//add arcs to original graph g
	for(int j = 0; j < num_edges; j++){
		node_u = 0; node_v = 0;
		while(node_u == node_v){
			node_u = node_id_rand(gen);
			node_v = node_id_rand(gen);
		}
		arc_cap = arc_cap_rand(gen);
		if(debug_level >= 2)
			cout << "Added arc between nodes " << node_u << " and " << node_v << " cap: " << arc_cap << endl;
		g->add_edge(node_u, node_v, arc_cap, arc_cap);
	}
}

GraphType::arc_id return_arc(int node_i, int node_j){
	return arc_pointer_list[make_pair(node_i, node_j)];
}

void update_tweights_residual(GraphType *g, int node_i, double new_scap, double new_tcap){
	if(debug_level >= 2)
	       cout << "Update terminal edges for  " << node_i + 1 << " " << new_scap << " " << new_tcap << endl; 
	
        double old_trcap = g-> get_trcap(node_i);	
	double old_t_arc_cap = g->get_t_arc_cap(node_i);

	//calculate new terminal residual for node i
	double new_trcap = old_trcap + (new_scap - new_tcap - old_t_arc_cap);	

	g -> set_trcap(node_i, new_trcap);
	g -> set_t_arc_cap(node_i, new_scap - new_tcap);
	g->mark_node(node_i);

}

void update_edge_residual(GraphType *g, GraphType::arc_id arc_ij, int new_cap_ij){
	// calculate residual capacity between i & j and j & u

 	GraphType::arc_id arc_ji = g->get_rev_arc(arc_ij); 

	double surplus, new_residual_ij, new_residual_ji;
	double trcap_i, trcap_j;
	double residual_ij = g->get_rcap(arc_ij);
        double residual_ji = g->get_rcap(arc_ji);	
	double cap_ij = g->get_arc_cap(arc_ij);
	double cap_ji = g->get_arc_cap(arc_ji); 
	double flow_ij = 0, flow_ji = 0;
	int node_i, node_j;
	g -> get_arc_ends(arc_ij, node_i, node_j);
	
	/*There cannot be flow in both directions */
	assert(residual_ij >= cap_ij || residual_ji >= cap_ji);

	/*Calculate flow values from residual capacities */
	if(residual_ij >= cap_ij){
		flow_ij = 0;
		flow_ji = cap_ji - residual_ji;
	}
	else {
		flow_ji = 0;
		flow_ij = cap_ij - residual_ij;
	}

	/* Update arc_ij */
	if(flow_ij > new_cap_ij){
		new_residual_ij = 0;
		new_residual_ji = new_cap_ij + cap_ji;
		surplus = (flow_ij - new_cap_ij);
		trcap_i = g -> get_trcap(node_i);
		trcap_j = g -> get_trcap(node_j);
		g -> set_trcap(node_i, trcap_i + surplus);
		g -> set_trcap(node_j, trcap_j - surplus);
	}
	else{
		new_residual_ij = residual_ij + (new_cap_ij - cap_ij);
		new_residual_ji = residual_ji;
	}

	g -> set_rcap(arc_ij, new_residual_ij);
	g -> set_rcap(arc_ji, new_residual_ji);
	g -> set_arc_cap(arc_ij, new_cap_ij);

	/* Mark nodes to reuse search trees */
	g->mark_node(node_i); g->mark_node(node_j);

}


int perform_experiment(int gen_seed) 
{

	random_device rd;
	mt19937 gen(rd());
	uniform_int_distribution<> node_id_rand(0, num_nodes - 1); 
	uniform_int_distribution<> arc_cap_rand(1, ARC_CAP_MAX);

	int node_u, node_v;
	double sweight, tweight, arc_cap;
	clock_t tStart, tEnd;
	int flow;

	GraphType::arc_id random_arc;

	for(double percent = 0; percent <= 1.01; percent += 0.05){

		cout << endl << endl << "% modification: " << percent*100 << endl;

		GraphType *s = new GraphType(num_nodes, num_edges);	

		create_new_graph(s, num_nodes, num_edges, gen_seed);

		//find time for maxflow
		tStart = clock();
		flow = s->maxflow();
		tEnd = clock();

		GraphType *t = new GraphType(num_nodes, num_edges);

		create_new_graph(t, num_nodes, num_edges, gen_seed);

		uniform_int_distribution<> arc_id_rand(0, s->get_arc_num() - 1); 
				
		if(percent == 1.0){
			for(int i = 0; i < num_nodes; i++){
				node_u = i;
				sweight = arc_cap_rand(gen); 
				tweight = arc_cap_rand(gen);
				t->add_tweights(node_u, sweight, tweight); 
				update_tweights_residual(s, node_u, sweight, tweight);
			}

			for(int i = 0; i < s->get_arc_num(); i++){
				random_arc = s->get_first_arc() + i;	
				arc_cap = arc_cap_rand(gen);
				update_edge_residual(s, random_arc, arc_cap);
				update_edge_residual(s, random_arc->sister, arc_cap);
				random_arc = t->get_first_arc() + i;
				t->set_rcap(random_arc, arc_cap);
				t->set_rcap(random_arc->sister, arc_cap);
							}	
		}
		else{
			//make random arc modifications
			for(int i = 0; i < percent*num_nodes; i++){
				node_u = node_id_rand(gen);	
				sweight = arc_cap_rand(gen); 
				tweight = arc_cap_rand(gen);
				t->add_tweights(node_u, sweight, tweight); 
				update_tweights_residual(s, node_u, sweight, tweight);

			}

			for(int j = 0; j < percent*num_edges; j++){

				int rand_arc_num = arc_id_rand(gen);	
				arc_cap = arc_cap_rand(gen);

				random_arc = s->get_first_arc() + rand_arc_num;	
				update_edge_residual(s, random_arc, arc_cap);
				update_edge_residual(s, random_arc->sister, arc_cap);

				random_arc = t->get_first_arc() + rand_arc_num;
				t->set_rcap(random_arc, arc_cap);
				t->set_rcap(random_arc->sister, arc_cap);
			}
		}	
		//find time for maxflow
		tStart = clock();
		flow = t->maxflow();
		tEnd = clock();

		cout << "Static maxflow time: " << (double)(tEnd - tStart)/(CLOCKS_PER_SEC) << endl;
		cout << "Flow value: " << flow << endl;

		//find time for maxflow
		tStart = clock();
		flow = s->maxflow();
		tEnd = clock();

		cout << "Dynamic maxflow time: " << (double)(tEnd - tStart)/(CLOCKS_PER_SEC) << endl;
		cout << "Flow value: " << flow << endl;

		delete t;
		delete s;
	}

	return 0;
}	

int main(int argc, char* argv[]){

	clock_t	tStart = clock();

	string log_path = "/home/pankaj/Max_of_convex_code_new/Code/output_logs/random_graph_time/trial/";
	
	srand(atoi(argv[1]));
	for(int j = 0; j < 5; j++){
		
		cout << "Iteration " << j << endl;
		string filename = log_path + "random_graph_time_" + to_string(j) + "_" + argv[1] + ".txt";
		ofstream out(filename);
		streambuf *coutbuf = cout.rdbuf(); //save old buf
		cout.rdbuf(out.rdbuf()); //redirect cout to filename

		perform_experiment(rand());

		cout.rdbuf(coutbuf); //reset to standard output again
	}

	clock_t	tEnd = clock();
	cout << "Total execution time: " << (double)(tEnd - tStart)/(CLOCKS_PER_SEC) << endl;

	return 0;
}
