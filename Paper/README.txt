22 March, 2016:

This folder contains the latex files for the ECCV '16 submission:

'Truncated Max-of-Convex Models' by Pankaj Pansari, Pawan Kumar

The contents of the directory are:

1. images - contains the pictures for the graph construction and depiction of
the concept
	a) sythetic_results: contains results for both linear and quadratic
experiments given in the paper and supplementary
	b) inpainting_results: contains results for 'house' and 'penguin' for
different parameter settings
	c) stereo_results: contains results for 'teddy', 'tsukuba', 'venus'
and 'cones' for different parameter settings

______________________________________________________________________________________________

Changes Required:

In main paper:

1. Highlight the fact that our bound is better than parsimonious labeling
(perhaps in the introduction).

2. Table 1: semicolon separating (a), (b) and (c) cases

3. m = 1 for quadratic case not specified in Fig 5.

4. section 5.2: Proposition 1: Parsimonious labeling - notation should be
consistent with our paper (what is r?)

5. Inpainting

section 6.2.1: Results - parameters for 'house' and 'penguin' have been
interchanged
	a. For `house', the parameters are $\omega_c$ = 40, $M$ = 40 and $m$ = 1, 3.
	b. For `penguin', the parameters are $\omega_c$ = 50, $M$ = 50 and $m$ = 1, 3.

6. Stereo

Fig. 7: Results for 'cone' to be included (already present in images/stereo
folder)

___________________________________________________________________________________________________
To make a sample ECCV paper, copy the contents of this directory
somewhere, and type

 latex eccv2016submission
 bibtex eccv2016submission
 latex eccv2016submission
 latex eccv2016submission

or 

 pdflatex eccv2016submission
 bibtex eccv2016submission
 pdflatex eccv2016submission
 pdflatex eccv2016submission
__________________________________________________________________________________________________
