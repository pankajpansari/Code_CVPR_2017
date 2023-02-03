function [uE pE hE E] = compute_energy(sG, Dc, hop, labels, metric, lambda, cliqueWeights)

% given sG, Sc, hop and current labeling - return the energy
if(length(lambda)>1)
    fprintf('\n\t\tWARNING: Inside Compute Energy: length(lambda)>1 \n');    
end
[nl nvar] = size(Dc);% based on sample images +

if(nargin<7)
   cliqueWeights = ones(nvar,1); 
end

% unary term
uE = sum(Dc( [1 nl]*( [labels(:)';1:nvar] -1) +1 ));

% pair-wise term - use only upper tri of sparseG
[rr cc]=find(sG);
low = rr>cc;
rr(low)=[];
cc(low)=[];
neq = labels(rr) ~= labels(cc);
pE = sum(single(full((sG( [1 size(sG,1)]*( [rr(neq(:))'; cc(neq(:))']-1 ) + 1 )))));

% HOpotentials energy
hE = 0;
for hi=1:numel(hop)
    
    nodes = hop(hi).ind;
    hopLabels = labels(nodes);
    uniqueLabels = unique(hopLabels);
    if(length(uniqueLabels)>1)
        hopPotential = getHOPpotential(uniqueLabels, metric);
        hE = hE+cliqueWeights(hi)*hopPotential;
    end
end
hE = lambda*hE;

E = uE + pE + hE;



    