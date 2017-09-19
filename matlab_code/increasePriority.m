function PM = increasePriority(PM,i,neighborhood)
%PM = increasePriority(PM,i,neighborhood)
%Increases priority of neighborhood if region i and sets it as the same of
%region i, which value is in PM. Updated PM is returned
global numWregions numHregions;
if (isfield(neighborhood,'north'))
    PM(neighborhood.north) = PM(i);
    neigh = getNeighborhood(neighborhood.north,numHregions, numWregions);
    if (isfield(neigh,'north'))
        PM(neigh.north) = PM(i);
    end
    if (isfield(neigh,'east'))
        PM(neigh.east) = PM(i);
    end
    if (isfield(neigh,'west'))
        PM(neigh.west) = PM(i);
    end
end
if (isfield(neighborhood,'south'))
    PM(neighborhood.south) = PM(i);
    neigh = getNeighborhood(neighborhood.south,numHregions, numWregions);
    if (isfield(neigh,'south'))
        PM(neigh.south) = PM(i);
    end
    if (isfield(neigh,'east'))
        PM(neigh.east) = PM(i);
    end
    if (isfield(neigh,'west'))
        PM(neigh.west) = PM(i);
    end
end
if (isfield(neighborhood,'west'))
    PM(neighborhood.west) = PM(i);
    neigh = getNeighborhood(neighborhood.west,numHregions, numWregions);
    if (isfield(neigh,'west'))
        PM(neigh.west) = PM(i);
    end
end
if (isfield(neighborhood,'east'))
    PM(neighborhood.east) = PM(i);
    neigh = getNeighborhood(neighborhood.east,numHregions, numWregions);
    if (isfield(neigh,'east'))
        PM(neigh.east) = PM(i);
    end
end
end