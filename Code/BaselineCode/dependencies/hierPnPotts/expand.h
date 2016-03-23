#ifndef __HOP_A_EXPAND_
#define __HOP_A_EXPAND_

#include <iostream>
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <sys/timeb.h>
#include "graph.h"
#include "energy.h"

using namespace std;


// Error function to be used by Graph class
#include <mex.h> // for error function
void my_err_func(char* msg)
{
    mexErrMsgIdAndTxt("robustpn:internal_error",msg);
}

// Alpha expansion class
// By Pushmeet Kohli, Lubor Ladicky, Phil Torr

// public functions :

// AExpand(Energy<termType> *e, int maxIter)
// - constructor for the class for solving energy e with maxIter number of iterations 

// void minimize(int *solution)
// - solves energy and saves into the solution array


//typedef double termType;
//typedef Graph<termType, termType, termType> Grapht;

template<typename termType>
class AExpand
{
	public:
        /*
         * Set initial parameters
         */
		AExpand(Energy<termType> *e, int maxIter)
		{
            maxiter = maxIter;
			energy = e;
			nvar = energy->nvar;
			npair = energy->npair;
			nhigher = energy->nhigher;
			nlabel = energy->nlabel;
            lambda = energy->lambda;
		}

        /*
         * minimize energy. solution need to be allocated externaly
         */
		termType minimize(int *solution, termType* ee = NULL)
		{
			int label_buf_num;
			int step;
			termType E_old, ue, pe, he;

            label_map = solution; // assignment of labels to nodes

            //check npair --> shouldn't it be (num_edges + numHigher*max_clique*2) ??

			g = new Graph<termType, termType, termType>(nvar + 2 * nhigher, npair, my_err_func);
			nodes = new node_id_t[nvar + 2 * nhigher]; // nodes in HOpotentials' graph

            E = compute_energy(ue, pe, he); // energy of current solution
            //cout<<"Lambda: "<<lambda<<"\n";
            //cout<<"\nEnergy for the given initialization: "<<E<<"\n";

			label_buf_num = nlabel;
			step = 0;

            int iter, label;
            termType E_new;
            E_new = E;
            bool failure = true;
            int outer_counter = 0;

            while(failure || iter<1)
            {
                for(label = 0; label < nlabel; label++) // for each label:
                {

                    E_new = expand(label, E_new);
                    g->reset();
                    //delete g;
                    //g = new Graph<termType, termType, termType>(maxNodes, maxPair, my_err_func);
                }
                outer_counter++;

                if(E_new<E) E = E_new;
                else failure = false;

                iter++;

                //if(outer_counter>=maxiter)  success = false;
                //else outer_counter++;

            }
            //cout<<"\nHierPn: outer_counter:"<<outer_counter;

            /*int iter, label;
            for(iter = 0; (iter < maxiter) && (label_buf_num > 0); iter++) //outer iteration of alpha expansion
			{ 
				for(label = 0; label < nlabel; label++) // for each label:
				{
					E_old = E;
                    //expand(label);
                    E_new = expand(label, E_new);
					g->reset();
					step++;
	        
					E = compute_energy(ue, pe, he); 
                    //cout<<E<<"\t";
                    if(E_old == E) label_buf_num--;  //if no change - we might be in optimum, try all other labels
                    else label_buf_num = nlabel - 1; // energy changed - retry all labels for new configuration
				}
                cout<<"\n";
            }*/
            //cout<<"\n";
/*            if ( iter == maxiter )
                mexWarnMsgIdAndTxt("robustpn:minimize", "Reached maximal number of iterations (%d)", iter);
  */          
			delete g;
			delete[] nodes;
            if (ee != NULL) {
                ee[0] = ue;
                ee[1] = pe;
                ee[2] = he;
            }
            return E;
		}

	private :
        typedef typename Graph<termType, termType, termType>::node_id node_id_t;
        
		int nvar;   // number of nodes (pixels)
        int npair;  // number of pair-wise potentials
        int nhigher; // number of HOpotentials
        termType lambda;

        int nlabel; // number of possible lables
		Graph<termType, termType, termType> *g; // min-cut/max-flow class
		node_id_t *nodes; // nodes in graph
		termType E; // current energy of state

		Energy<termType> *energy; // HO-energy formulation
		int *label_map; // current assignment of labels to nodes - **not allocated inside this class**
		int maxiter, i, j; 

        /*
         * Expanding label 
         * In an alpha-expansion step, each node may either retain its label
         * or be labeled "alpha"
         */
        termType expand(int label, termType E_old)
		{
			termType constE = 0; 
			bool *is_active;
            int label_bar;

		
			is_active = new bool[nvar]; // all !is_active nodes in the potential will participate in move (may change their labels to alpha)
			
            /* build the graph */
            // unary terms - connect non-active nodes to source/sink
			for(i = 0; i < nvar; i++)
			{
				label_bar = label_map[i];
				if(label_bar == label)
				{
					is_active[i] = true; // active nodes has already label alpha
					//constE += energy -> unaryCost[i * nlabel + label];
				}
				else
				{
					is_active[i] = false;
					nodes[i] = g -> add_node(); // add node to graph for this participating variable
					g->add_tweights(nodes[i], energy->unaryCost[i * nlabel + label], energy->unaryCost[i * nlabel + label_bar]); // conect the node like in regular energy minimization                    
				}
			}

			int from, to;
			termType weight;

            // binary-terms
			for(i = 0; i < npair; i++)
			{
				from = energy->pairIndex[2*i];	
				to = energy->pairIndex[2*i+1];
				weight = energy->pairCost[i];

				if(is_active[from] && is_active[to]) continue;
				else if((is_active[from]) && (!is_active[to])) {
                    g->add_tweights(nodes[to], 0, weight);
                    
                } else if((!is_active[from]) && (is_active[to])) {
                    g->add_tweights(nodes[from], 0, weight);
                } else {
					if(label_map[from] == label_map[to]) {
                        g -> add_edge(nodes[from], nodes[to], weight, weight);
                    } else {
						g->add_tweights(nodes[from], 0, weight);
						g->add_edge(nodes[from], nodes[to], 0, weight);
					}
				}
			}

            // Higher-order terms for Pn-Potts model
            termType gamma_max, gamma, gamma_alpha, weight_d, weight_e;
            int gamma_label;

            for(i = 0;i < nhigher; i++)
            {
		if(energy->lambda>0){

                gamma_max = energy->higherCost[i * (nlabel + 1) + nlabel]; // gamma_max
                gamma_alpha = energy->higherCost[i * (nlabel + 1) + label];  // gamma_label (alpha)

                nodes[2*i+nvar] = g->add_node(); // add auxilary node m_1

                weight_d = lambda*(gamma_max - gamma_alpha); // check

                g->add_tweights(nodes[2 * i + nvar],0,weight_d); // r_1
                for(j = 0; j < energy->higherElements[i]; j++)
                {
                    if (!is_active[energy->higherIndex[i][j]]) g->add_edge(nodes[2 * i + nvar],nodes[energy->higherIndex[i][j]], 0, weight_d);

                }

                gamma_label =  find_uniform_label(i);

                if(gamma_label != -1){

                    gamma = energy->higherCost[i * (nlabel + 1) + gamma_label];
                    weight_e = lambda*(gamma_max - gamma);

                    nodes[2*i+nvar+1] = g->add_node();
                    g->add_tweights(nodes[2 * i + nvar +1], weight_e, 0);

                    for(j = 0; j < energy->higherElements[i]; j++)
                    {
                        if (!is_active[energy->higherIndex[i][j]]) g->add_edge(nodes[2 * i + nvar + 1],nodes[energy->higherIndex[i][j]], weight_e,0);

                    }
                }
		}
            }

            // Higher-order terms for Robust Pn-Potts model
            /*termType lambda_a, lambda_b, lambda_m, gamma_b, number_old;
			int maxLabel;
            termType weight_new = 0.0;

            for(i = 0;i < nhigher; i++)
			{
				maxLabel = getMaxLabel(i); // get dominant label 
	            
				lambda_m = energy->higherCost[i * (nlabel + 1) + nlabel]; // gamma_max 
				lambda_a = energy->higherCost[i * (nlabel + 1) + label];  // gamma_label (alpha)

				nodes[2*i+nvar] = g->add_node(); // add auxilary node m_1
                
                weight_new = lambda*(lambda_m - lambda_a); // check
				g->add_tweights(nodes[2 * i + nvar],0,weight_new); // r_1
				for(j = 0; j < energy->higherElements[i]; j++)
				{
                    if (!is_active[energy->higherIndex[i][j]]) // add only if the node is not assigned the label of alpha
						g->add_edge(nodes[2 * i + nvar],nodes[energy->higherIndex[i][j]], 0,
                            energy->higherWeights[i][j]*lambda*(lambda_m - lambda_a) / energy->higherTruncation[i]); // check
				}
				if((maxLabel == -1) || (maxLabel == label)) // no dominant label
				{
					number_old = 0;
					lambda_b = energy->higherCost[i * (nlabel + 1) + nlabel]; //gamma_max of alpha - no m_0 node
				}
				else // there exist a dominant label
				{
					number_old = cardinality(i, maxLabel);// weights of nodes labeld dominant in current potential (w_i influencing)
					lambda_b = energy->higherCost[i * (nlabel + 1) + maxLabel] + // gamma_d
                        (energy->higherP[i] - number_old) // R_d including weights
							*(energy->higherCost[i * (nlabel + 1) + nlabel] - energy->higherCost[i * (nlabel + 1) + maxLabel]) // gamma_max - gamma_d
                            *(1 / energy->higherTruncation[i]); // 1/Q

					gamma_b = energy->higherCost[i * (nlabel + 1) + maxLabel];

					nodes[2*i+nvar+1] = g->add_node(); // auxilary node m_0
                    
                    weight_new = lambda*(lambda_m - lambda_b); // check
					g->add_tweights(nodes[2 * i + nvar + 1],weight_new,0); //weight r_0

					for(j = 0; j < energy->higherElements[i]; j++)
						if (label_map[energy->higherIndex[i][j]] == maxLabel) // connect dominant-labeled nodes to m_0
							g->add_edge(nodes[2 * i + nvar + 1],nodes[energy->higherIndex[i][j]], 
                                energy->higherWeights[i][j]*lambda*(lambda_m - gamma_b) / energy->higherTruncation[i],0); // check
				}
				//constE -= lambda_m - (lambda_a + lambda_b); // const offset delta
            }*/


            g -> maxflow();

            int *label_map_old = new int[nvar];
            for(i = 0; i<nvar; i++) label_map_old[i] = label_map[i];

            for(i = 0; i<nvar; i++){
                 if((!is_active[i]) && (g->what_segment(nodes[i]) == Graph<termType, termType, termType>::SINK)) label_map[i] = label; // expand label alpha
            }

            termType E_new, ue_new, pe_new, he_new;
            E_new = compute_energy(ue_new, pe_new, he_new);

            //cout<<"E_old: "<<E_old<<"\tE_new: "<<E_new<<"\n";

            delete[] is_active;

            if(E_new <= E_old){
                delete[] label_map_old;
                return E_new;
            }
            else{
                for(i = 0; i<nvar; i++) label_map[i] = label_map_old[i];
                //cout<<"CAUTION(Pn-Potts): E_new ("<<E_new<<") > E_old ("<<E_old<<")\n";
                delete[] label_map_old;                
                return E_old;
            }


            /*for(i = 0; i<nvar; i++)
                if((!is_active[i]) && (g->what_segment(nodes[i]) == Graph<termType, termType, termType>::SINK)) 
                    label_map[i] = label; // expand label alpha 
			
			// termType newE = compute_energy(); // - will be done outside this function
            delete[] is_active;*/
		}

        /*
         * For HOpotential i, choose dominant label (-1 if there is not dominant label) - can be at most one
         * label d s.t.: W(c_d) > P - Q_d,  
         */

        int find_uniform_label(int i)
        {
            int j, gamma_label;
            int *num_labels = new int[nlabel];

            for(j = 0;j < nlabel; j++) {
                num_labels[j] = 0;
            }
            for(j = 0;j < energy->higherElements[i]; j++) {
                num_labels[label_map[energy->higherIndex[i][j]]]++;
            }

            int number=0;

            for(j = 0;j < nlabel; j++)
            {
                if(number <= num_labels[j])
                {
                    number = num_labels[j];
                    gamma_label = j;
                }

            }

            delete[] num_labels;

            if(number != energy->higherElements[i]) gamma_label = -1;

            return gamma_label;
        }

        int getMaxLabel(int i)
        {
            int j;
            termType *num_labels = new termType[nlabel];

            for(j = 0;j < nlabel; j++)
                num_labels[j] = 0;

            for(j = 0;j < energy->higherElements[i]; j++)
                num_labels[label_map[energy->higherIndex[i][j]]]+= energy->higherWeights[i][j];

            termType number = 0;
            int maxLabel;

            for(j = 0;j < nlabel; j++)
            {
                if(number <= num_labels[j])
                {
                    number = num_labels[j];
                    maxLabel = j;
                }
            }

            delete[] num_labels;
            if(number > (energy->higherP[i] - energy->higherTruncation[i])) // Assumes same Q for all labels
                return maxLabel;
            else
                return -1;
        }



        /*
         * For HO-potential i sum w_j delta_label(x_j)
         */
		termType cardinality(int i, int label)
		{
			int j;
            termType count_label = 0;

			for(j = 0;j<energy->higherElements[i]; j++)
				if(label_map[energy->higherIndex[i][j]] == label)  
					count_label+=energy->higherWeights[i][j];
			
			return count_label;
		}


        /*
         * Compute current solution's (label_map) energy
         */

        // for Pn-potts model
        termType compute_energy(termType& ue, termType& pe, termType& he)
        {

            int i;
            termType gamma_max;


            ue = 0; // unary term energy
            pe = 0; // pair-wise potentials energy
            he = 0; // high-order potentials energy

            // collect Dc - unary terms
            for(i = 0; i < nvar; i++)
                ue += energy->unaryCost[i * nlabel + label_map[i]];

            // pair-wise terms. Assuming Sc=[0 1;1 0]
            for(i = 0; i < npair; i++)	{
                if(label_map[energy->pairIndex[2 * i]] != label_map[energy->pairIndex[2 * i + 1]])
                    pe += energy->pairCost[i];
            }

            int uniform_label;
            // collect HOpotenatials terms
            for(i = 0; i < nhigher; i++)    // for each HOpotential
            {
                gamma_max = energy->higherCost[i * (nlabel + 1) + nlabel];

                uniform_label = find_uniform_label(i);
                if(uniform_label == -1) he += gamma_max;
                else he += energy->higherCost[i * (nlabel + 1) + uniform_label];
            }
            he = he*lambda;

            return ue + pe + he;
        }

        // for Robust Pn-potts model
        /*termType compute_energy(termType& ue, termType& pe, termType& he)
		{
			
			int i, j;
			
            ue = 0; // unary term energy
            pe = 0; // pair-wise potentials energy
            he = 0; // high-order potentials energy
            
            // collect Dc - unary terms
			for(i = 0; i < nvar; i++)
				ue += energy->unaryCost[i * nlabel + label_map[i]];
			
            // pair-wise terms. Assuming Sc=[0 1;1 0]
			for(i = 0; i < npair; i++)	{
				if(label_map[energy->pairIndex[2 * i]] != label_map[energy->pairIndex[2 * i + 1]])
					pe += energy->pairCost[i];
			}
			
            // sum w_i delta_j(x_i)
            termType *W = new termType[nlabel];
            
            // collect HOpotenatials terms
			for(i = 0; i < nhigher; i++)    // for each HOpotential
			{
				for(j = 0; j < nlabel; j++) W[j] = 0;

                // count how many nodes are labeled L in the potential i
				for(j = 0; j < energy->higherElements[i]; j++) 
                    W[label_map[energy->higherIndex[i][j]]]+=energy->higherWeights[i][j];

                
				termType cost, minCost = energy->higherCost[(nlabel + 1) * i + nlabel]; // gamma_max

				for(j = 0;j < nlabel; j++)
				{
					cost = energy->higherCost[(nlabel + 1) * i + j] + // gamma_j 
                        (energy->higherP[i] - W[j])     //  P - sum w_i \delta_j(x_c)
							* (energy->higherCost[(nlabel + 1) * i + nlabel]-energy->higherCost[(nlabel + 1) * i + j]) // gamma_max - gamma_j
                            * (1 / energy->higherTruncation[i]);    // 1 / Q
					if (minCost >= cost) minCost = cost;
				}
				// add HOpotential's energy to the total term
				he += minCost;
			}
            he = he*lambda;

			delete[] W;

			return ue + pe + he;
        }*/
};
#endif // __HOP_A_EXPAND_
