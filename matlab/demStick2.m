% DEMSTICK2 Model the stick man using an RBF kernel and dynamics.

% FGPLVM

% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

dataSetName = 'stick';
experimentNo = 2;

% load data
[Y, lbls] = lvmLoadData(dataSetName);

% Set up model
numActive = 100;
latentDim = 2;

% Train using the full training conditional (i.e. no approximation.)
model = fgplvmCreate(Y, latentDim, 'ftc', numActive, {'rbf', 'bias', 'white'}, 'gaussian');

% Add dynamics model.
model = fgplvmAddDynamics(model, {'rbf', 'white'}, 100);
model.dynamics.kern.comp{1}.inverseWidth = 0.2;

% Optimise the model.
iters = 1000;
display = 1;

model = fgplvmOptimise(model, display, iters);

% Save the results.
capName = dataSetName;;
capName(1) = upper(capName(1));
save(['dem' capName num2str(experimentNo) '.mat'], 'model');

% load connectivity matrix
[void, connect] = mocapLoadTextData('run1');
% Load the results and display dynamically.
fgplvmResultsDynamic(dataSetName, experimentNo, 'stick', connect)
