Parsimonious Labeling Code -- ICCV2015
Author: Puneet K. Dokania (puneetkdokania@gmail.com)


All the mex files are in the `dependencies' folder. Don't touch them until you  what to modify the algorithm itself.
All the matlab wrappers are in the `matlabcodes' folder.

Go to the `matlabcodes' folder and run following commands

1) Run startup_all.m
2) Run 'compile_all.m' 
3) Test the functionalities by running following functions
    experimentsGivenRandomMetric('testMetric')
    experimentsGivenRandomCluster('testCluster')
4) The stereo experiment code is in the `stereo_experiments' folder.
    look into the `stereoExample.m' file to start with
5) The inpainting experiment code is in the `inpainting_experiments' folder. 
    look into the `inpaintingExample.m' file to start with

This code is a wrapper for following algorithms
1) alpha expansion for Pn potts model
2) alpha expansion for co-occurence based potential
3) hierarchical pn potts model
4) parsimonious labeling
5) mean shift based super pixel generation
6) converting any metric to mixture of tree metrics
7) integrates the GCO library for label cost. Therefore, many standard algorithms can be used. 
For example, alpha expansion for metric labeling with pairwise cliques.

Applications
1) Image inpainting and denoising
2) Stereo matching


 == Things to do ==
1) Make the hierPn code fast by adding the step of tracking the clusterID of the label in the C++ wrapper.
2) Make Co-oc and hierPn code fast by solving the pairwise case using alpha-expansion. Check if this can be done efficiently. Treating pairwise as a clique is quite expensive.
