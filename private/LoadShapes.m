function S=LoadShapes

s={'private/cities','private/states','private/major_roads','private/counties'};

load(s{1});
S.cities=cities;

load(s{2});
S.states=states;

load(s{3});
S.major_roads=major_roads;

load(s{4});
S.counties=counties;


