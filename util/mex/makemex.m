function makemex

disp(' ')
files={'isopmex5.c','ele2neimex5.c','contmex5.c','findelemex5.c','findelemex52.c','read_adcirc_fort_compact_mex.c','read_adcirc_fort_mex.c'};
for i=1:length(files)
   disp(sprintf('Compiling %s',files{i}))
   com=sprintf('mex %s',files{i});
   eval(com);
end

disp(' ')
!icc -ansi -fPIC band.c -c
files={'divgmex5.c','gradmex5.c','curlmex5.c'};
for i=1:length(files)
   disp(sprintf('Compiling %s',files{i}))
   com=sprintf('mex %s band.o ',files{i});
   eval(com);
end

disp(['Add ' pwd ' to your MATLABPATH'])
disp(' ')
