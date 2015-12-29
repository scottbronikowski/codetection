addpath(genpath('/home/sbroniko/codetection/source/new-sentence-codetection/forests_edges_boxes'))
cd /home/sbroniko/codetection/source/new-sentence-codetection/forests_edges_boxes/
%diary install_warnings.txt
mex private/edgesDetectMex.cpp -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
mex private/edgesNmsMex.cpp -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
mex private/spDetectMex.cpp -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
mex private/edgeBoxesMex.cpp -outdir private '-DUSEOMP' CFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp"
model=load('/home/sbroniko/codetection/source/new-sentence-codetection/forests_edges_boxes/models/forest/modelBsds.mat');
model=model.model;
%diary off
cd ..
disp('complete with InstallEdgeBoxes');