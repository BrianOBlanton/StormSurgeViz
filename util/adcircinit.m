function adcircinit
%ADCIRCINIT a setup file for ADCIRC matlab directories and datafiles.
% ADCIRCINIT is a script that adds paths and variables to
% the local workspace so that matlab functions written for
% finite element work can be accessed.
 
%LabSig  Brian O. Blanton
%        Renaissance Computing Institute
%        University of North Carolina
%        Chapel Hill, NC
%                 27517
%
%        Brian_Blanton@Renci.Org
%

ADCIRC = fileparts(which(mfilename));

lp={'mex','basics','fem'};

for i=1:length(lp)
       addpath(fullfile(ADCIRC, lp{i})); 
end

