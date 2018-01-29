function cRes = calcRes(model, modelMets, fMap, calcPaths)


% score the production scores, degradation scores and the aggregate 
% perturbation score using the extracted pathways

pProdString = cell(length(modelMets.metIndsActive),1);
wProdString = cell(length(modelMets.metIndsActive),1);
pDegString = cell(length(modelMets.metIndsActive),1);
wDegString = cell(length(modelMets.metIndsActive),1);
scoresProd = NaN*ones(length(modelMets.metIndsActive),1);
scoresDeg = NaN*ones(length(modelMets.metIndsActive),1);
pValLowProd = NaN*ones(length(modelMets.metIndsActive),1);
pValHighProd = NaN*ones(length(modelMets.metIndsActive),1);
pValLowDeg = NaN*ones(length(modelMets.metIndsActive),1);
pValHighDeg = NaN*ones(length(modelMets.metIndsActive),1);
pCurSS = cell(length(modelMets.metIndsActive),1);
dCurSS = cell(length(modelMets.metIndsActive),1);
numPerms = 1000;


for i = 1:length(modelMets.metIndsActive)
    %% prod
    curPathProd = calcPaths.pathwaysProd(i,:);
    curRxnsActive = model.rxns(find(curPathProd));
    curRxnsMap = intersect(curRxnsActive, fMap.corrRxnUniqueData);
    curRxnIndsMap = cell2mat(cellfun(@(x) find(strcmp(x,model.rxns)),curRxnsMap,'UniformOutput',false));
    curWeights = abs(curPathProd(curRxnIndsMap)/sum(abs(curPathProd(curRxnIndsMap))));
    
    curCell = curRxnsMap;
    curString = '';
    if ~isempty(curCell)
        for j = 1:(length(curCell)-1)
            curString = [curString num2str(curCell{j}) ';'];
        end
        curString = [curString num2str(curCell{end})];
    end
    pProdString{i} = curString;
    
    curMat = curWeights;
    curString = '';
    if ~isempty(curCell)
        for j = 1:(length(curCell)-1)
            curString = [curString num2str(curMat(j)) ';'];
        end
        curString = [curString num2str(curMat(end))];
    end
    wProdString{i} = curString;
    
    curFoldInds = cell2mat(cellfun(@(x) find(strcmp(x,fMap.corrRxnUniqueData)),curRxnsMap,'UniformOutput',false));
    if ~isempty(curFoldInds)
        curFolds = fMap.foldChangeRxnData(curFoldInds);
        curScoreProd = nansum(curWeights.*curFolds'); % replaced sum with nansum
        scoresProd(i) = curScoreProd;
        [pValLow, pValHigh] = pathStats(curScoreProd, curWeights, fMap.foldChangeRxnData, numPerms);
        pValLowProd(i) = pValLow;
        pValHighProd(i) = pValHigh;
    end
    
    % add SS info
    if ~isempty(curCell)
        tmp_curSS = model.subSystems(match(curCell, model.rxns));
        if ~isempty(tmp_curSS)
            pSS(i,1) = cell2string(tmp_curSS);
        end
    end
    
    % levels
    ind = match(curRxnsMap, curRxnsActive(~findregexp(curRxnsActive,'^DM_',1)));
    
    try
        levels = strsplit(calcPaths.levelsProd{i}, ';');
    catch
        levels = split(calcPaths.levelsProd(i), ';');    
    end
    
    Plevels(i) = cell2string(levels(ind));

%% deg
    curPathDeg = calcPaths.pathwaysDeg(i,:);
    curRxnsActive = model.rxns(find(curPathDeg));
    curRxnsMap = intersect(curRxnsActive, fMap.corrRxnUniqueData);
    curRxnIndsMap = cell2mat(cellfun(@(x) find(strcmp(x,model.rxns)),curRxnsMap,'UniformOutput',false));
    curWeights = abs(curPathDeg(curRxnIndsMap)/sum(abs(curPathDeg(curRxnIndsMap))));
    curFoldInds = cell2mat(cellfun(@(x) find(strcmp(x,fMap.corrRxnUniqueData)),curRxnsMap,'UniformOutput',false));
    if ~isempty(curFoldInds)
        curFolds = fMap.foldChangeRxnData(curFoldInds);
        curScoreDeg = nansum(curWeights.*curFolds'); % replaced sum with nansum,
        scoresDeg(i) = curScoreDeg;
        [pValLow, pValHigh] = pathStats(curScoreDeg, curWeights, fMap.foldChangeRxnData, numPerms);
        pValLowDeg(i) = pValLow;
        pValHighDeg(i) = pValHigh;
    end
    
    curCell = curRxnsMap;
    curString = '';
    if ~isempty(curCell)
        for j = 1:(length(curCell)-1)
            curString = [curString num2str(curCell{j}) ';'];
        end
        curString = [curString num2str(curCell{end})];
    end
    pDegString{i} = curString;
    
    curMat = curWeights;
    curString = '';
    if ~isempty(curCell)
        for j = 1:(length(curCell)-1)
            curString = [curString num2str(curMat(j)) ';'];
        end
        curString = [curString num2str(curMat(end))];
    end
    wDegString{i} = curString;
    
    % ss info
    if ~isempty(curCell)
        tmp_curSS = model.subSystems(match(curCell, model.rxns));
        if ~isempty(tmp_curSS)
            dSS(i,1) = cell2string(tmp_curSS);  
        end
    end
    
    % levels
    ind = match(curRxnsMap, curRxnsActive(~findregexp(curRxnsActive,'^DM_',1)));
    try
        levels = strsplit(calcPaths.levelsDeg{i}, ';');
    catch
        levels = split(calcPaths.levelsDeg(i), ';');
    end
    Dlevels(i) = cell2string(levels(ind));
    
    
end



cRes.pLevel = Plevels';
cRes.dLevel = Dlevels';
cRes.pProdString = pProdString;
cRes.wProdString = wProdString;
cRes.scoresProd = scoresProd;
cRes.pDegString = pDegString;
cRes.wDegString = wDegString;
cRes.scoresDeg = scoresDeg;
cRes.dSubSyst=dSS;
cRes.pSubSyst=pSS;
cRes.pValLowProd = pValLowProd;
cRes.pValHighProd = pValHighProd;
cRes.pValLowDeg = pValLowDeg;
cRes.pValHighDeg = pValHighDeg;


