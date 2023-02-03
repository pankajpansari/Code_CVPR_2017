#ifndef __HOP_A_EXPAND_
#define __HOP_A_EXPAND_

#include <iostream>
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <sys/timeb.h>
#include "graph.h"
#include "energy.h"
#include<set>
#include<algorithm>
#include<vector>

using namespace std;

#define MAX(x,y) ((x) < (y) ? (y) : (x))
#define MIN(x,y) ((x) > (y) ? (y) : (x))

// Error function to be used by Graph class
#include <mex.h> // for error function
void my_err_func(char* msg)
{
    mexErrMsgIdAndTxt("cooc:internal_error",msg);
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

        cout<<"\nTrying to allocate memory for the graph\n\n";
        int maxNodes = nvar + nhigher * (nlabel + 1);
        //int maxPair = npair + 2*nvar;
        int maxPair = npair + nhigher*100;// max 10x10 cliques
        g = new Graph<termType, termType, termType>(maxNodes, maxPair, my_err_func);

        cout<<"\nSuccessfully allocated memory for the graph\n\n";

        //g = new Graph<termType, termType, termType>(nvar + 2 * nhigher, npair, my_err_func);

        //nodes = new node_id_t[nvar + 2 * nhigher]; // nodes in HOpotentials' graph
        //nodes = new node_id_t[nvar + nhigher * (nlabel + 1)]; // nodes in HOpotentials' graph
        nodes = new node_id_t[nvar]; // nodes the graph (without auxiliary)
        //nodes = new node_id_t[maxNodes]; // nodes the graph (without auxiliary)

        //cout<<"Max nodes: "<<maxNodes<<endl;

        cout<<"\nComputing energy\n\n";
        E = compute_energy(ue, pe, he); // energy of current solution
        cout<<"\nenergy computed\n\n";
        cout<<"Energy Old: "<<E_old<<"\n";
        //cout<<"Lambda: "<<lambda<<"\n";


        label_buf_num = nlabel;
        step = 0;

        int iter, label;
        termType E_new;
        E_new = E;
        bool failure = true;
        int outer_counter = 0;
        iter = 0;
        //for(iter = 0; (iter < maxiter) && (label_buf_num > 0); iter++) //outer iteration of alpha expansion
        while(failure || iter<2)
        {
            for(label = 0; label < nlabel; label++) // for each label:
            {

                cout<<"\ngoing inside expand for label "<<label<<"\n\n";
                E_new = expand(label, E_new);
                cout<<"\noutside expand, resetting graph "<<label<<"\n\n";
                g->reset();
                cout<<"\ngraph resetting done "<<label<<"\n\n";
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
        cout<<"\nCooc: outer_counter:"<<outer_counter;


        /*int iter, label;
            for(iter = 0; (iter < maxiter) && (label_buf_num > 0); iter++) //outer iteration of alpha expansion
            {
                for(label = 0; label < nlabel; label++) // for each label:
                {
                    E_old = E;
                    expand(label, E_old);
                    g->reset();
                    step++;

                    E = compute_energy(ue, pe, he);
                    cout<<E<<"\t";
                    if(E_old == E) label_buf_num--;  //if no change - we might be in optimum, try all other labels
                    else label_buf_num = nlabel - 1; // energy changed - retry all labels for new configuration
                }
                cout<<"\n";
            }*/

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
    int nlabel; // number of possible lables
    termType lambda;

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

        cout<<"\ninside expand for label "<<label<<"\n\n";
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
                constE += energy -> unaryCost[i * nlabel + label];

                //nodes[i] = g -> add_node(); // add node, may be required at the time of using high order potentials
            }
            else
            {
                is_active[i] = false;
                nodes[i] = g -> add_node(); // add node to graph for this participating variable
                g->add_tweights(nodes[i], energy->unaryCost[i * nlabel + label], energy->unaryCost[i * nlabel + label_bar]); // conect the node like in regular energy minimization
            }
        }

        cout<<"\nunary nodes/edges added\n";

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

        cout<<"\npairwise nodes/edges added\n";

        // High order for co-occurence based potentials
        // Things to do:
        //    (a) find the set of current labels in the clique under consideration --> let's call it currLabelSet
        //    (b) num of auxiliary = |currLabelSet| + 1;
        //    (c) compute K_{\alpha}, and K_l
        //
        /* find the unique label set of the current labeling */


        // find_unique_labels();

        cout<<"\nhigh order started\n";

        vector<int> clique_label_set[nhigher];
        vector<int>::iterator it;

        /* find the set of unique labels in each clique based on the current labeling */
        for(int c=0;c<nhigher;c++){

            for(i = 0; i<energy->higherElements[c];i++) { clique_label_set[c].push_back(label_map[energy->higherIndex[c][i]]); }

            sort( clique_label_set[c].begin(), clique_label_set[c].end() );
            it = unique( clique_label_set[c].begin(), clique_label_set[c].end() );
            clique_label_set[c].resize( distance(clique_label_set[c].begin(), it ) );
        }

        /* graph construction for the high-order cliques */
        int aux_count=0;
        float k1alpha = 0.0, k2l=0.0;
        bool alpha_present;
        node_id_t *aux_nodes;

        //cout<<"\n alpha: "<<label;

        vector<int> alpha; alpha.push_back(label); // note that alpha is the label under consideration for the expansion step
        for(i = 0;i < nhigher; i++)
        {
            //cout<<energy->cliqueWeights[i]<<"\n";

            aux_count=0;
            aux_nodes = new node_id_t[clique_label_set[i].size()+1];

            set<int> setA(clique_label_set[i].begin(),clique_label_set[i].end() );
            alpha_present = setA.find(label) != setA.end();

            set<int> setAwithAlpha = setA;
            setAwithAlpha.insert(label);

            vector<int> vecA(setA.begin(), setA.end());
            vector<int> vecAwithAlpha(setAwithAlpha.begin(), setAwithAlpha.end());

            if(!alpha_present){
                /* find C(A+alpha), C(A) */
                k1alpha = lambda*( clique_potential( vecAwithAlpha ) - clique_potential( vecA ) );
                k1alpha *= energy->cliqueWeights[i];

                if(k1alpha<0) { cout<<"\n\tCaution: k1alpha negative: "<<k1alpha<<"\n"; k1alpha = 0.0; }

                aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{\alpha}
                g->add_tweights( aux_nodes[aux_count], 0.0, k1alpha ); // add unary
                for (int k = 0; k<energy->higherElements[i];k++){
                    g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], 0.0, k1alpha); // add pairwise
                }
                aux_count++;

            }

            /* add other aux variables (zl) and their corresponding edges */
            for(int j = 0; j<clique_label_set[i].size();j++) {
                if(clique_label_set[i][j] != label){

                    int currLabel = clique_label_set[i][j];
                    set<int> setAwithAlphaNoLabel = setAwithAlpha;
                    setAwithAlphaNoLabel.erase (setAwithAlphaNoLabel.find(currLabel));
                    vector<int> vecAwithAlphaNoLabel(setAwithAlphaNoLabel.begin(), setAwithAlphaNoLabel.end());

                    k2l = lambda*( clique_potential( vecAwithAlpha ) - clique_potential(vecAwithAlphaNoLabel) );
                    k2l *= energy->cliqueWeights[i];

                    if(k2l<0) { cout<<"\n\tCaution: k2l negative: "<<k2l<<"\n"; k2l = 0.0; }

                    aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{l} where l is not equal to alpha
                    g->add_tweights( aux_nodes[aux_count], k2l, 0.0 );

                    for (int k = 0; k<energy->higherElements[i];k++){
                        if(label_map[energy->higherIndex[i][k]]==clique_label_set[i][j]){
                            g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], k2l, 0.0); // add pairwise
                        }
                    }
                    aux_count++;
                }
            }

            delete [] aux_nodes;

        }

         cout<<"\nhigh order done\n";


        g -> maxflow();

         cout<<"\nmax-flow done\n";

        int *label_map_old = new int[nvar];
        for(i = 0; i<nvar; i++) label_map_old[i] = label_map[i];

        cout<<"\nwhat->segment started\n";
        for(i = 0; i<nvar; i++){
            if((!is_active[i]) && (g->what_segment(nodes[i]) == Graph<termType, termType, termType>::SINK)) label_map[i] = label; // expand label alpha
        }

        cout<<"\nnew labeling done, computing energy\n";

        termType E_new, ue_new, pe_new, he_new;
        E_new = compute_energy(ue_new, pe_new, he_new);

        cout<<"E_old: "<<E_old<<"\tE_new: "<<E_new<<"\n";


        if(E_new <= E_old){
            delete[] label_map_old;
            delete[] is_active;
            return E_new;
        }
        else{
            for(i = 0; i<nvar; i++) label_map[i] = label_map_old[i];
            //cout<<"CAUTION(Co-oc): E_new ("<<E_new<<") > E_old ("<<E_old<<")\n";
            delete[] label_map_old;
            delete[] is_active;
            return E_old;
        }



        // compute energy, if energy is less then only update it
        /*

            //cout<<E_new<<"\n";
            if(E_new<=E_old){
                for(i = 0; i<nvar; i++)
                    if((!is_active[i]) && (g->what_segment(nodes[i]) == Graph<termType, termType, termType>::SINK))
                        label_map[i] = label; // expand label alpha

            }*/





        // termType newE = compute_energy(); // - will be done outside this function
        ////delete[] is_active;

        //return MIN(E_old, E_new);
        //return E_old;
    }

    /*void find_unique_labels(){


            // find the set of unique labels in each clique based on the current labeling
            for(int c=0;c<nhigher;c++){

                for(int i1 = 0; i1<energy->higherElements[c];i1++) { clique_label_set[c].push_back(label_map[energy->higherIndex[c][i1]]); }

                sort( clique_label_set[c].begin(), clique_label_set[c].end() );
                it = unique( clique_label_set[c].begin(), clique_label_set[c].end() );
                clique_label_set[c].resize( distance(clique_label_set[c].begin(), it ) );
            }
        }*/



    /*float clique_potential(vector<int> *label_set){


            //cout<<"\nchecking rhst : "<<energy->rhstMetricCost[0]<<" "<<energy->rhstMetricCost[24]<<"\n";

            int num_labels = label_set->size(), iLabel, jLabel;
            float potential = 0.0;

            if(num_labels == 1){
                //cout<<"inside clique_potential: num_labels == 1\n";
                return potential;
            }

            for (int i1=0; i1<num_labels; i1++){
                for(int j1=i1; j1<num_labels; j1++){
                    iLabel = label_set->at(i1);
                    jLabel = label_set->at(j1);
                    //potential = MAX(potential, labelSet[ iLabel ][ jLabel ]);
                    potential = MAX(potential, energy->rhstMetricCost[ iLabel*energy->nlabel + jLabel ]);
                }
            }

            return potential;
        }*/

    vector<int> get_set_difference (vector<int> *first, vector<int> *second){

        int sizeMax = first->size() + second->size();
        vector<int> final (sizeMax);
        vector<int>:: iterator it;

        sort(first->begin(), first->end());
        sort(second->begin(), second->end());

        it = set_difference(first->begin(), first->end(), second->begin(), second->end(), final.begin() );
        final.resize( distance( final.begin(), it ) );

        return final;
    }

    vector<int> get_set_union (vector<int> *first, vector<int> *second){

        int sizeMax = first->size() + second->size();
        vector<int> final (sizeMax);
        vector<int>:: iterator it;

        //sort(first->begin(), first->end());
        //sort(second->begin(), second->end());

        it = set_union(first->begin(), first->end(), second->begin(), second->end(), final.begin() );
        final.resize( distance( final.begin(), it ) );

        sort( final.begin(), final.end() );
        it = unique( final.begin(), final.end() );
        final.resize( distance(final.begin(), it ) );

        return final;
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
    termType compute_energy(termType& ue, termType& pe, termType& he)
    {

        int ii;

        ue = 0.0; // unary term energy
        pe = 0.0; // pair-wise potentials energy
        he = 0.0; // high-order potentials energy


        // collect Dc - unary terms
        for(ii = 0; ii < nvar; ii++)
            ue += energy->unaryCost[ii * nlabel + label_map[ii]];

        cout<<"\nunary done, npair "<<npair<<"\n\n";

        // pair-wise terms. Assuming Sc=[0 1;1 0]
        for(ii = 0; ii < npair; ii++)	{
            if(label_map[energy->pairIndex[2 * ii]] != label_map[energy->pairIndex[2 * ii + 1]])
                pe += energy->pairCost[ii];
        }

        cout<<"\npairwise done \n\n";

        // collect HOpotenatials terms
        // for each HOP, find the set of unique labels and use the potential function to compute the energy

        cout<<"nhigher: "<<nhigher<<"\n";
        //cout<<"num elements clique (10): "<<energy->higherElements[10]<<"\n";
        /*vector<int> clique_label_set1[nhigher];
        vector<int>::iterator it1;

        // find the set of unique labels in each clique based on the current labeling and then compute the clique potential based on the unique label set
        for(int c=0;c<nhigher;c++){
            //cout<<"c: "<<c<<"num elements: "<<energy->higherElements[c]<<"\n";
            cout<<"pushing\n";
            for(ii = 0; ii<energy->higherElements[c];ii++) {
                clique_label_set1[c].push_back(label_map[energy->higherIndex[c][ii]]);
            }
            cout<<"sorting\n";
            sort( clique_label_set1[c].begin(), clique_label_set1[c].end() );
            cout<<"finding unique\n";
            it1 = unique( clique_label_set1[c].begin(), clique_label_set1[c].end() );
            cout<<"resizing\n";
            clique_label_set1[c].resize( distance(clique_label_set1[c].begin(), it1 ) );
            cout<<"done\n";

            // compute clique potential
            //he += energy->cliqueWeights[c]*clique_potential(clique_label_set1[c]);
            he = 0;
        }*/


        /*vector<int>::iterator it1;
        vector<int> clique_label_set1;

        // find the set of unique labels in each clique based on the current labeling and then compute the clique potential based on the unique label set
        for(int c=0;c<nhigher;c++){
            //cout<<"c: "<<c<<"num elements: "<<energy->higherElements[c]<<"\n";

            cout<<"pushing\n";
            for(ii = 0; ii<energy->higherElements[c];ii++) {
                clique_label_set1.push_back(label_map[energy->higherIndex[c][ii]]);
            }
            cout<<"sorting\n";
            sort( clique_label_set1.begin(), clique_label_set1.end() );
            cout<<"finding unique\n";
            it1 = unique( clique_label_set1.begin(), clique_label_set1.end() );
            cout<<"resizing\n";
            clique_label_set1.resize( distance(clique_label_set1.begin(), it1 ) );
            cout<<"done\n";

            // compute clique potential
            //he += energy->cliqueWeights[c]*clique_potential(clique_label_set1[c]);
            he = 0;
            clique_label_set1.clear();
        }*/



        // find the set of unique labels in each clique based on the current labeling and then compute the clique potential based on the unique label set
        set<int> clique_label_set1;
        for(int c=0;c<nhigher;c++){
            for(ii = 0; ii<energy->higherElements[c];ii++) {
                clique_label_set1.insert(label_map[energy->higherIndex[c][ii]]);
            }
            if(clique_label_set1.size() == 1)
                continue;
            else{
                vector<int> label_set_vec(clique_label_set1.begin(), clique_label_set1.end());
                he += energy->cliqueWeights[c]*clique_potential(label_set_vec);
            }
            clique_label_set1.clear();
        }

        //he = 0;
        he *= lambda;
        cout<<"\nhigh order done \n\n";
        //cout<<he<<"\n";

        return ue + pe + he;
    }

    float clique_potential(vector<int> &label_set){

        /*int labelSet[5][5] = { { 0, 24, 10, 10 , 24},
              { 24, 0, 26, 26, 8},
              { 10, 26, 0, 4, 26},
              { 10, 26, 4, 0, 26},
              { 24, 8, 26, 26, 0}
              };
              */
        /*int labelSet[7][7] = { {0,23  ,  23,    54,   112,   227,   227},
                                {23,     0,     8,    54,   112,   227,   227},
                                {23,     8,     0,    54,   112,   227,   227},
                                {54,    54,    54,     0,   112,   227,   227},
                                {112,   112,   112,   112,     0,   227,   227},
                                {227,   227,   227,   227,   227,     0,   110},
                                {227,   227,   227,   227,   227,   110,     0}
                             };
                             */
        //cout<<"\nchecking rhst : "<<energy->rhstMetricCost[0]<<" "<<energy->rhstMetricCost[24]<<"\n";

        int num_labels = label_set.size(), iLabel, jLabel;
        float potential = 0.0, potential1 = 0.0;

        if(num_labels == 1){
            //cout<<"inside clique_potential: num_labels == 1\n";
            return potential;
        }

        for (int i1=0; i1<num_labels; i1++){
            for(int j1=0; j1<num_labels; j1++){
                iLabel = label_set.at(i1);
                jLabel = label_set.at(j1);
                //potential1 = MAX(potential1, labelSet[ iLabel ][ jLabel ]);
                potential = MAX(potential, energy->rhstMetricCost[ iLabel*energy->nlabel + jLabel ]);

                //cout<<"iLabel: "<<iLabel<<"\tjLabel: "<<jLabel<<" potential: "<<energy->rhstMetricCost[ iLabel*energy->nlabel + jLabel ]<<"\n";

            }
        }

        //cout<<"potential1: "<<potential1<<"\tpotential: "<<potential<<"\n";

        return potential;
    }
    /*        termType compute_energy_robustpn(termType& ue, termType& pe, termType& he)
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
            delete[] W;

            return ue + pe + he;
        }
        */
};

#endif // __HOP_A_EXPAND_

/*

// High order for co-occurence based potentials
// Things to do:
//    (a) find the set of current labels in the clique under consideration --> let's call it currLabelSet
//    (b) num of auxiliary = |currLabelSet| + 1;
//    (c) compute K_{\alpha}, and K_l
//


int cliqueLabelSet[nhigher][nlabel], card[nhigher],c, foundIt=0, tot_no_alpha_cliques = 0, max_card=0;
bool alphaPresent[nhigher];

for(c = 0; c<nhigher; c++){
cliqueLabelSet[c][0] = label_map[energy->higherIndex[c][0]];
card[c] = 1;
foundIt=0;

if(cliqueLabelSet[c][0] == label) alphaPresent[c] = true;
else alphaPresent[c] = false;

for (i = 1; i < energy->higherElements[c]; i++) {
for (j = 0; j < card[c]; j++) {
if(label_map[energy->higherIndex[c][i]]==cliqueLabelSet[c][j]) foundIt = 1;
if(cliqueLabelSet[c][j] == label) alphaPresent[c] = true;
}
if(!foundIt) { cliqueLabelSet[c][card[c]] = label_map[energy->higherIndex[c][i]], card[c]++; }
else foundIt=0;
}

if(!alphaPresent[c]) {
tot_no_alpha_cliques++;
max_card = MAX(max_card, card[c]);
}
}

//cout<<"alpha: "<<label<<endl;
//cout<<"max cardinality: "<<max_card<<endl;
//cout<<"total no alpha cliques: "<<tot_no_alpha_cliques<<endl;

int j,k;
int aux_count=0;
float kalpha = 0.0, kl=0.0;

node_id_t *aux_nodes;

for(i = 0;i < nhigher; i++)
{
aux_count=0;
aux_nodes = new node_id_t[card[i]+1];

if(!alphaPresent[i]){

kalpha = rand() % 100 + 1;

aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{\alpha}
g->add_tweights(aux_nodes[aux_count], 0.0, kalpha); // add unary
for (k = 0; k<energy->higherElements[i];k++){
g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], 0.0, kalpha); // add pairwise
}

aux_count++;
}


// add other aux variables (zl) and it's corresponding edges
for(j = 0; j<card[i];j++) {
if(cliqueLabelSet[i][j]!=label){ // this doesn't look correct as kalpha'' may not be zero if kalpha' is zero

kl = rand() % 200 + 1;
}
kl = 200+1;

aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{l} where l is not equal to alpha
g->add_tweights(aux_nodes[aux_count], kl, 0.0); // add unary

for (k = 0; k<energy->higherElements[i];k++){
    if(label_map[energy->higherIndex[i][k]]==cliqueLabelSet[i][j]){
        g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], kl, 0.0); // add pairwise
    }
}
aux_count++;


}

delete [] aux_nodes;

}

*/



/*
   int labelSet[5][5] = { { 0, 24, 10, 10 , 24},
   { 24, 0, 26, 26, 8},
   { 10, 26, 0, 4, 26},
   { 10, 26, 4, 0, 26},
   { 24, 8, 26, 26, 0}
   };




   find the unique label set and the cardinality of the label set for each high order clique
   vector<int> clique_label_set[nhigher];
   vector<int>::iterator it;

   for(int c=0;c<nhigher;c++){
   for(i = 0; i<energy->higherElements[c];i++) clique_label_set[c].push_back(label_map[energy->higherIndex[c][i]]);
   sort( clique_label_set[c].begin(), clique_label_set[c].end() );
   unique( clique_label_set[c].begin(), clique_label_set[c].end() );
   }


//cout<<"alpha: "<<label<<endl;
//cout<<"max cardinality: "<<max_card<<endl;
//cout<<"total no alpha cliques: "<<tot_no_alpha_cliques<<endl;

int j,k;
int aux_count=0;
float k1alpha = 0.0, k2l=0.0;
bool alpha_present;

node_id_t *aux_nodes;

for(i = 0;i < nhigher; i++)
{
aux_count=0;
aux_nodes = new node_id_t[clique_label_set[i].size()+1];

// find whether alpha exist in the current label set or not
it = find( clique_label_set[i].begin(), clique_label_set[i].end(), label);
if(it!=clique_label_set[i].end()) alpha_present=true;
else alpha_present = false;

if(!alpha_present){

k1alpha = rand() % 100 + 1;

aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{\alpha}
g->add_tweights(aux_nodes[aux_count], 0.0, k1alpha); // add unary
for (k = 0; k<energy->higherElements[i];k++){
g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], 0.0, k1alpha); // add pairwise
}

aux_count++;
}


// add other aux variables (zl) and it's corresponding edges
for(j = 0; j<clique_label_set[i].size();j++) {

if(clique_label_set[i][j]!=label) k2l = rand() % 200 + 1;
else k2l = rand() %100 + 1; // compute k2alpha

aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{l} where l is not equal to alpha
g->add_tweights(aux_nodes[aux_count], k2l, 0.0); // add unary

for (k = 0; k<energy->higherElements[i];k++){
if(label_map[energy->higherIndex[i][k]]==clique_label_set[i][j]){
g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], k2l, 0.0); // add pairwise
}
}
aux_count++;

}

delete [] aux_nodes;
*/


/*
                    /*if(!alpha_present) {
                        // C(A), C(A-alpha)
                        k2l = clique_potential( &setAwithAlpha ) - clique_potential( &setAwithAlphaNoLabel );

                    }if(alpha_present && clique_label_set[i][j]==label ){

                        k2l = clique_potential(&setA) - clique_potential(&setAnoAlpha);
                        //k2l = 0;
                    }
                    else {

                        //k2l = rand() %100 + 1; // compute k2alpha
                        //cout<< clique_potential(&setA)<<"  "<< clique_potential(&setAnoAlphaNoLabel)<<"\n";
                        float c1 = clique_potential(&setAnoAlpha) - clique_potential(&setAnoAlphaNoLabel);
                        float c2 = clique_potential(&setA) - clique_potential(&setAnoAlpha) - clique_potential(&setAnoLabel) + clique_potential(&setAnoAlphaNoLabel);
                        //cout<<"c1: "<<c1<<"\tc2: "<<c2<<"\n";
                        k2l = MIN( c1,c2 );
                        //k2l = c1;
                    }*/


/*
           // find_unique_labels();

            vector<int> clique_label_set[nhigher];
            vector<int>::iterator it;

            // find the set of unique labels in each clique based on the current labeling
            for(int c=0;c<nhigher;c++){

                for(i = 0; i<energy->higherElements[c];i++) { clique_label_set[c].push_back(label_map[energy->higherIndex[c][i]]); }

                sort( clique_label_set[c].begin(), clique_label_set[c].end() );
                it = unique( clique_label_set[c].begin(), clique_label_set[c].end() );
                clique_label_set[c].resize( distance(clique_label_set[c].begin(), it ) );
            }

            // graph construction for the high-order cliques
            int aux_count=0;
            float k1alpha = 0.0, k2l=0.0;
            bool alpha_present;
            node_id_t *aux_nodes;

            vector<int> alpha; alpha.push_back(label); // note that alpha is the label under consideration for the expansion step
            for(i = 0;i < nhigher; i++)
            {
                aux_count=0;
                aux_nodes = new node_id_t[clique_label_set[i].size()+1];

                // find whether alpha exist in the current label set or not
                it = find( clique_label_set[i].begin(), clique_label_set[i].end(), label);
                if(it!=clique_label_set[i].end()) alpha_present=true;
                else alpha_present = false;

                // declare some sets

                vector<int> setA (clique_label_set[i]); // initialize with the unique labels in the clique
                //vector<int> setAnoAlpha = get_set_difference( &setA, &alpha);
                vector<int> setAwithAlpha = get_set_union( &setA, &alpha);


                if(!alpha_present){
                    // find C(A+alpha), C(A)

                    k1alpha = clique_potential( &setAwithAlpha ) - clique_potential( &setA );
                    k1alpha = lambda*k1alpha;

                    if(k1alpha<0) { cout<<"\n\tCaution: k1alpha negative: "<<k1alpha<<"\n"; k1alpha = 0.0; }

                    aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{\alpha}
                    g->add_tweights( aux_nodes[aux_count], 0.0, k1alpha ); // add unary
                    for (int k = 0; k<energy->higherElements[i];k++){
                        g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], 0.0, k1alpha); // add pairwise
                    }
                    aux_count++;
                }

                // add other aux variables (zl) and their corresponding edges
                for(int j = 0; j<clique_label_set[i].size();j++) {
                    if(clique_label_set[i][j] != label){

                    k2l = 0.0;
                    vector<int> currLabel; currLabel.push_back(clique_label_set[i][j]);
                    ////vector<int> alphaCurrLabel; alphaCurrLabel.push_back(label); alphaCurrLabel.push_back(clique_label_set[i][j]);
                    //vector<int> setAnoLabel = get_set_difference( &setA, &currLabel);
                    ////vector<int> setAwithAlphaNoLabel = get_set_difference( &setAwithAlpha, &currLabel);
                    //vector<int> setAnoAlphaNoLabel = get_set_difference( &setA, &alphaCurrLabel);


                    if(!alpha_present) {
                        vector<int> setAwithAlphaNoLabel = get_set_difference( &setAwithAlpha, &currLabel);
                        k2l = clique_potential( &setAwithAlpha ) - clique_potential( &setAwithAlphaNoLabel );
                    }
                    else {
                        vector<int> setAnoLabel = get_set_difference( &setA, &currLabel);
                        k2l = clique_potential(&setA) - clique_potential(&setAnoLabel);
                    }

                    k2l = lambda*k2l;
                    //if(k2l<1E-6) k2l = 0.0;

                    if(k2l<0) { cout<<"\n\tCaution: k2l negative: "<<k2l<<"\n"; k2l = 0.0; }

                    aux_nodes[aux_count] = g->add_node(); // add auxilary node z_{l} where l is not equal to alpha
                    //if(clique_label_set[i][j] != label) g->add_tweights(aux_nodes[aux_count], k2l, 0.0); // add unary

                    for (int k = 0; k<energy->higherElements[i];k++){
                        //if(label_map[energy->higherIndex[i][k]]==clique_label_set[i][j] && clique_label_set[i][j] != label){
                        if(label_map[energy->higherIndex[i][k]]==clique_label_set[i][j]){
                            g->add_edge(aux_nodes[aux_count], nodes[energy->higherIndex[i][k]], k2l, 0.0); // add pairwise
                        }
                    }
                    aux_count++;
                    }

                }

                delete [] aux_nodes;

            }
*/
