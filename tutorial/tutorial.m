% % Tutorial

clear all

%% Set up paths

% MetPath uses functions from Cobra Toolbox package
% (https://opencobra.github.io/cobratoolbox/stable/).
% Its installation is mandatory.
%If you have not yet run initCobraToolbox, do so here (otherwise skip)
run initCobraToolbox


%% Set current directory

% Change the current directory to the MetPath folder
cd('E:\Dropbox (Personal)\MetChange 2.0\Submission Files\MetPath Toolbox')

%% Load tutorial variables

% In order to use MetPath toolbox we need:
% - a struct object (named fc in supplemented files) with (1)expression
% data (double) of condition 1, (2) expression data (double) of condition 2,
% (3) gene names.

% - working models (named model_ana and model_std in supplemented files)
% where the Ex rxns reflect the growing conditions.

load('data\tutorial_data\tutorialStart');
load('data\cucoPairs');

%% Set up solvers

% Any solver handled by the COBRA toolbox can be used
changeCobraSolver('gurobi', 'MIQP')
changeCobraSolver('gurobi','LP');
changeCobraSolver('gurobi','QP');
changeCobraSolver('gurobi','MILP');


%%

% for anaerobic condition convert the model to be handled by the toolbox, define the flux state and generate modelMets struct object necessary for the next steps with:

biomass_ind = strmatch('BIOMASS',model_std.rxns);
biomass_ind = [];

[model_ana,modelMets_ana] = defineMets(model_ana, biomass_ind, 2, currencyPairs, cofactorPairs, compartments,1,0);
%% REMOVE

% or with additional options: (FBA with low tollerance, allowing loops
% and with a user provided list of inorganic metabolites


inorganicMets = {'o2', 'so2','so3','so4','nh4','no2','no3','fe2','fe3', 'h2o','co2','co','h2o2','o2s','h2s',...
    'etha', 'no','fe3hox','3fe4s','4fe4s','2fe2s', 'etoh','mobd','cu','cu2'};

%NEED TO UPDATE THIS LINE WITH THE NEW OPTIONS
[model_ana,modelMets_ana] = defineMets(model_ana, biomass_ind,2,1,inorganic_mets);

% % NOTE: biomass index must be provided, in fact, it involves too many
% % metabolites and otherwise it will be included in several pathways altering results.
% % you can find biomass_ind by biomass_ind = strmatch('BIOMASS', model_ana.rxns);

%%

% map the fold change of genes expression onto active reactions.

fMap_ana = mapGenes(model_ana, fc.genes, fc.anaerobic, fc.aerobic);

% % NOTE: the first expression data must refers to the used model and
% % condtion used for the function

% extract the pathways and calculate the production scores, degradation
% scores and the aggregate perturbation scores

[resultsTab_ana, cRes_ana] = metPath(model_ana, modelMets_ana, fMap_ana,1,0.05);

% % NOTE: the cutoffdistance is setted to 1 in order to run the tutorial
% % faster. For each metabolite extract the reactions involved in the
% % production and in its degradation, estimate their weightings and their
% % levels. The levels are meant as the distance from the reaction directly
% % involved in the production of the metabolite.

% % the user can set the distance of the rxns to take in consideration during
% % the pathways extraction (cutoffDistance). It is not suggested to use a
% % distance too high since it leads to an increment of the time needed and
% % to a loss of statistical power. A distance of 2 or 3 is a good tradeoff.
% % Since some reactions, specially at longer distances, partecipate barely
% % in the pathway is possible to set a threshold to filter out that reactions
% % (cutoffFraction)


% to obtain the aggregate perturbation score (APS) in a sorted cell array we can
% use the following function:

aggregatePerturbationScores = APS(modelMets_ana, cRes_ana);


%% Second set of analyses

% In order to retrieve the subSystems perturbation score it is necessary
% compare the scores of the two differents conditions. Thus, what was done
% for the anaerobic growing conditions has to be done also for the aerobic
% growing conditions:

%DEFINE METS SHOULDN"T PRINT ANYTHING EITHER

%WHY IS MAP GENES SO SLOW??

[model_std,modelMets_std] = defineMets(model_std, biomass_ind, 2, currencyPairs, cofactorPairs, compartments,1,0);
fMap_std = mapGenes(model_std, fc.genes, fc.aerobic, fc.anaerobic);
[resultsTab, cRes_std] = metPath(model_std, modelMets_std, fMap_std, 1, 0.05);


% Then we can score the subSystems Perturbation by

subSystemsPerturbation = subSystemsScores(model_ana, cRes_ana, modelMets_ana,model_std, cRes_std, modelMets_std);

% this function will predict the overall perturbation of the subSystems in the model


% generate an output compatible with escher: suppose we want study the
% cytosolic pyruvate pathway in the two condition, we can obtain an output
% (to cut and paste on a txt file and load on (escher.github.io) which
% describe the rxn scores fold change for each rxns in that pathway

% In order to use escherPaths function we need to set which is the first
% condition and the second condition:

fc.expression1 = fc.anaerobic;
fc.expression2 = fc.aerobic;

% In this case the lofFC values will be obtained by comparing anaerobic
% conditions vs aerobic conditions

% then we can run the option

file = escherPaths('pyr_c', 'b',model_ana,fc, cRes_ana,modelMets_ana,cRes_std,modelMets_std);

% alternatively we can study the pathway in a single condition by:

file = escherPaths('pyr_c', 'b',model_ana,fc, cRes_ana,modelMets_ana);

% % NOTE: the 'b' stands for 'both' (production and degradation), if we want study just the production or
% % degradation for a specific metabolite we can use respectvively 'p' or
% 'd'


% to generate a table with a comparisons in terms of perturbation score and
% used rxns we can use the comparePaths function:

[commonPaths, diffPaths] = comparePaths(model_ana,model_std,cRes_ana,cRes_std, modelMets_ana,modelMets_std);

% % NOTE: in this case, since we extracted paths using a distance = 1 they
% will result exactly the same except for the perturbation score.


% findGenesFromPaths:  it permits to retrieve involved genes in a pathway
% (in production reactions, degradation reactions and in th whole path)

[Pgenes, Dgenes, PDgenes] = findGenesFromPaths(cRes_ana, model_ana, modelMets_ana);





%% universalDB - E. Coli

load tutorialUniversalDb

% first of all the index of the genes of expression data must match those from
% universal database. It is possible to use data from chip array or from
% RNA-seq. In the latter case, if data for standard condition are not
% provided the function will use microarray data from standard conditions.
% Thus, data values will be converted in rank score values in order to
% allow a comparison of array data and rna seq data.
% the data used in this tutorial are the same used to obtain results
% described in the paper and they come from rna seq. In order to match the
% data and to rank them we can run the ollowing function:

[data_matched] = matchExpressionData(data, 1);

% % NOTE: data must contains two fields:
% % one named genes and one named vals RNAseq is a flag value
% % specifying if used data are from RNAseq experiment, standardExpression
% % can be empty (in this case will be used data from package) or user can
% % provide his own expression data.

listCond = {'acetateaerobicNH4.mat'
    'acetateanerobicNH4.mat'
    'acetateanerobicNO3.mat'
    'ala_ana.mat'
    'ala_o2.mat'
    'arg_ana.mat'
    'arg_o2.mat'
    'asn_ana.mat'
    'asn_o2.mat'
    'asp_ana.mat'
    'asp_o2.mat'
    'cys_ana.mat'
    'cys_o2.mat'
    'fumarateaerobicNH4.mat'
    'fumarateanerobicNH4.mat'
    'fumarateanerobicNO3.mat'
    'galaerobicNH4.mat'
    'galanaerobicNH4.mat'
    'galanaerobicNO3.mat'
    'glcAerobicNH4.mat'
    'glcAnaerobicNH4.mat'
    'glcAnaerobicNH4_2.mat'
    'glcAnaerobicNo3.mat'
    'gln_ana.mat'
    'gln_o2.mat'
    'glu_ana.mat'
    'glu_o2.mat'
    'gly_ana.mat'
    'gly_o2.mat'
    'glycaerobicNH4.mat'
    'glycanaerobicNH4.mat'
    'glycanaerobicNO3.mat'
    'glycolateaerobicNH4.mat'
    'glycolateanerobicNH4.mat'
    'glycolateanerobicNO3.mat'
    'his_ana.mat'
    'his_o2.mat'
    'iso_ana.mat'
    'iso_o2.mat'
    'lacAerobicNH4.mat'
    'lacAnaerobicNH4.mat'
    'lacAnaerobicNo3.mat'
    'leu_ana.mat'
    'leu_o2.mat'
    'lys_ana.mat'
    'lys_o2.mat'
    'mannoseaerobicNH4.mat'
    'mannoseanaerobicNH4.mat'
    'mannoseanaerobicNO3.mat'
    'met_ana.mat'
    'met_o2.mat'
    'phe_ana.mat'
    'phe_o2.mat'
    'pro_ana.mat'
    'pro_o2.mat'
    'succinateaerobicNH4.mat'
    'succinateanerobicNH4.mat'
    'succinateanerobicNO3.mat'
    'thr_ana.mat'
    'thr_o2.mat'
    'trp_ana.mat'
    'trp_o2.mat'
    'tyr_ana.mat'
    'tyr_o2.mat'
    'val_ana.mat'
    'val_o2.mat'};

%  after data preparation, we can use universalDb function by means of
%  ranked genes (data_matched.rank or .standardRank)
%
[pathways, perturbationScores, universal_ssScore] = universalDb(model,data_matched.genes,data_matched.rank,data_matched.standardRank, 1, listCond)

% % NOTE: exprs1 = genes values or ranked genes list from user's data
% % expression, exprs2 = genes values or ranked genes list from standard
% % conditions. ssScore = flag to score also the subSystems score, optional
% % since it drastically increase the computational time)
%
% % Usage example:
% % [pathways, perturbationScores, universal_ssScore] = universalDb(model,data_matched.genes,data_matched.vals,data_matched.standardVals, 1)

%Ok there's no reason universalDB needs to take a year. The condition files
%already have the pathways. Need to just extract those pathways and map the
%data directly

%WHERE IS THE FUNCTION THAT LOOKS AT SIMILARITY OF PATHWAYS WHEN
%GENERATING A UNIVERSAL DB TO COLLAPSE SIMILAR PATHWAYS?


