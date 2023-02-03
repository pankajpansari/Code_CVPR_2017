#include "readConfigFile.h"

/****************************************************************************************************/

/* This function reads the configuration file (in the standard format) and returns an inputParameter type variable*/
inputParameters read_file(const string& fileName)
{
    inputParameters newInput;

    fstream myfile(fileName.c_str(), std::ios_base::in);
    
    myfile >> newInput.nvar >> newInput.nlabel >> newInput.M >> newInput.m;
    
    cout << "Parameters of the input file:" << endl << endl;
    cout << "Number of variables = " << newInput.nvar << endl;
    cout << "Number of labels = " << newInput.nlabel << endl;

    cout << "M = " << newInput.M << " m =  " << newInput.m << endl;

    assert(("Number of variables should be positive" &&  newInput.nvar > 0));
    assert(("Number of labels should be positive" && newInput.nlabel > 0));
    assert(("m should be positive" && newInput.m > 0));
    
    myfile.get();
    
    for(int variable_count = 0; variable_count < newInput.nvar; variable_count++){
    	vector<double> unary_current_variable;
    	string line;
    	getline(myfile, line);
    	istringstream iss(line);
    	double unary;
    	while(iss >> unary){
    		unary_current_variable.push_back(unary);
    	}

	assert("One or more labels not assigned unary potential" && (int) unary_current_variable.size() == newInput.nlabel);
    	newInput.unary_potentials.push_back(unary_current_variable);	
    }
    
	myfile >> newInput.distance_type;
	assert("Distance function type should be either 1 for linear or 2 for quadratic" && (newInput.distance_type== 1 || newInput.distance_type== 2));
	
	if(newInput.distance_type == 1){
		for(int i = 0; i < newInput.nlabel; i ++){
			newInput.distance_func.push_back(double(i));
		}
	}
	else{
		for(int i = 0; i < newInput.nlabel; i ++){
			newInput.distance_func.push_back(double(i*i));
		}	
	}

	myfile >> newInput.nclique;

	cout << "Total number of cliques = " << newInput.nclique << endl;

	for(int clique = 0; clique < newInput.nclique; clique++){
		int size;
		myfile >> size;
		assert("Clique size must be greater than 0" && size > 0);
		newInput.clique_sizes.push_back(size);
		vector<int> current_clique_members;
		for(int variable_count = 0; variable_count < size; variable_count++){
			int variable_id;
		 	myfile >> variable_id;
			assert("Variable ids must be greater than non-negative and less than total number of variables" && variable_id > 0 && variable_id <= newInput.nvar);
			current_clique_members.push_back(variable_id - 1);
		}
		newInput.clique_members.push_back(current_clique_members);
		double weight;
		myfile >> weight;
		assert("Clique weights cannot be negative" && weight >= 0);			
		newInput.clique_weight.push_back(weight);
	}

	myfile.close();
	return newInput;
}

/****************************************************************************************************/

/* This function reads the labeling contained in filename (separated by space) and returns a vector. 
   Its purpose is to read a labeling of another algorithm and compute its energy for debugging purposes.*/ 
vector<int> read_labeling(const string filename){

	vector<int> labeling;
	ifstream infile(filename);
	int current_label;

	while (infile >> current_label)
		labeling.push_back(current_label - 1);

	infile.close();
	return labeling;
}

/****************************************************************************************************/

/* This function writes the given labeling (whether final or intermediate) to the given filename. 
   The labeling can then be visualized by being read by matlab or python code. */
void write_labeling(vector<int> labeling, const string filename){
	ofstream out(filename);
	int label_count = 0;
	int max = (int) labeling.size();

	while(label_count < max){
		cout << labeling[label_count] << "\n";
		label_count++;
	}
	out.close();
}

/****************************************************************************************************/

/* This function takes in the number of the unary file (1 for unary_1.txt, contained in ../Data/Unary/) and other parameters,
 * assumes cliques as overlapping sliding windows, generates clique memberships and stores the corresponding information in the inputParameter type variable.*/
inputParameters generate_synthetic_input(double M, int m, double clique_weight, int unary_num, int distance_type){

	//Initialize the values of parameters known already	
	inputParameters syntheticInput;
	int sizex = 100, sizey = 100, size_window = 10;
	syntheticInput.nvar = sizex * sizey;
	syntheticInput.nlabel = 20;
	syntheticInput.M = M;
	syntheticInput.m = m;
	
	//read unary file
	string filename = "/home/pankaj/Max_of_convex_code_new/Data/Unary/unary_" + to_string(unary_num) + ".txt";
	fstream input_file(filename.c_str(), ios_base::in);
	
	for(int variable_count = 0; variable_count < syntheticInput.nvar; variable_count++){
    		vector<double> unary_current_variable;
	    	string line;
    		getline(input_file, line);
	    	istringstream iss(line);
    		double unary;
	    	while(iss >> unary){
    			unary_current_variable.push_back(unary);
	    	}
		assert("One or more labels not assigned unary potential" && (int)unary_current_variable.size() == syntheticInput.nlabel);
	    	syntheticInput.unary_potentials.push_back(unary_current_variable);	
    	}
 
	syntheticInput.distance_type = distance_type;
	syntheticInput.nclique = (sizey - size_window + 1)*(sizex - size_window + 1);

	if(syntheticInput.distance_type == 1){
		for(int i = 0; i < syntheticInput.nlabel; i ++){
			syntheticInput.distance_func.push_back(double(i));
		}
	}
	else{
		for(int i = 0; i < syntheticInput.nlabel; i ++){
			syntheticInput.distance_func.push_back(double(i*i));
		}	
	}

	for(int i = 0; i < sizex - size_window + 1; i++){
		for(int j = 0; j < sizey - size_window + 1; j++){
			vector<int> members_current_clique;
			for(int k = i; k < i + size_window; k ++){
				for(int p = j; p < j + size_window; p++){
					int var_num = k * sizey + p;
					members_current_clique.push_back(var_num);
				}
			}
			syntheticInput.clique_members.push_back(members_current_clique);
			syntheticInput.clique_weight.push_back(clique_weight);
			syntheticInput.clique_sizes.push_back(size_window * size_window);
		}
	}
	//write to a file the parameter values and unary values
	//write clique memberships and weights
	//save file	
	return syntheticInput;
}

/****************************************************************************************************/

/* This function takes in the number of the unary file (1 for unary_1.txt, contained in ../Data/Unary/) and other parameters,
 * assumes 4-connected pairwise relationships, generates clique memberships and stores the corresponding information in the inputParameter type variable.*/
inputParameters generate_synthetic_input_4connected(double M, int m, double clique_weight, int unary_num, int distance_type){
	//Initialize the values of parameters known already	
	inputParameters syntheticInput;
	int sizex = 100, sizey = 100;
	syntheticInput.nvar = sizex * sizey;
	syntheticInput.nlabel = 20;
	syntheticInput.M = M;
	syntheticInput.m = m;
	int nclique = 0;

	//read unary file
	string filename = "../Data/Unary/unary_" + to_string(unary_num) + ".txt";
	fstream input_file(filename.c_str(), ios_base::in);
	
	for(int variable_count = 0; variable_count < syntheticInput.nvar; variable_count++){
    		vector<double> unary_current_variable;
	    	string line;
    		getline(input_file, line);
	    	istringstream iss(line);
    		double unary;
	    	while(iss >> unary){
    			unary_current_variable.push_back(unary);
	    	}
		assert("One or more labels not assigned unary potential" && (int)unary_current_variable.size() == syntheticInput.nlabel);
	    	syntheticInput.unary_potentials.push_back(unary_current_variable);	
    	}
 
	syntheticInput.distance_type = distance_type;

	if(syntheticInput.distance_type == 1){
		for(int i = 0; i < syntheticInput.nlabel; i ++){
			syntheticInput.distance_func.push_back(double(i));
		}
	}
	else{
		for(int i = 0; i < syntheticInput.nlabel; i ++){
			syntheticInput.distance_func.push_back(double(i*i));
		}	
	}

	for(int i = 0; i < sizex; i++){
		for(int j = 0; j < sizey; j++){
			if((i - 1) >= 0){	
				syntheticInput.clique_members.push_back({i*sizey + j, (i-1)*sizey + j});
				syntheticInput.clique_weight.push_back(clique_weight);
				syntheticInput.clique_sizes.push_back(2);
				nclique = nclique + 1;	
			}
			if((j + 1) < sizey){
				syntheticInput.clique_members.push_back({i*sizey + j, i*sizey + j + 1});
				syntheticInput.clique_weight.push_back(clique_weight);
				syntheticInput.clique_sizes.push_back(2);		
				nclique = nclique + 1;
			}
		}
	}
	syntheticInput.nclique = nclique;
	return syntheticInput;
}

/****************************************************************************************************/

/* This function takes in an inputParameter variable and prints the information contained in it (in the form of the configuration file).
 * This can be useful to inspect the contents for small examples for debugging purposes.*/
void printInputParameter(inputParameters newInput){
	cout << newInput.nvar << " " << newInput.nlabel << endl;
	cout << newInput.M << endl;
	cout << newInput.m << endl;
	for(int i = 0; i < newInput.nvar; i++){
		for(int j = 0; j < newInput.nlabel; j++){
			cout << newInput.unary_potentials[i][j] << " ";		
		}
		cout << endl;
	}
//	cout << newInput.distance_type << endl;
	cout << newInput.nclique << endl;
	for(int i = 0; i < newInput.nclique; i++){
		int clique_size = newInput.clique_sizes[i];
		cout << clique_size << " ";
		for(int j = 0; j < clique_size; j++){
			cout << newInput.clique_members[i][j] + 1 << " ";
		}
		cout << endl;
		cout << newInput.clique_weight[i] << endl;
	}
}


/****************************************************************************************************/


