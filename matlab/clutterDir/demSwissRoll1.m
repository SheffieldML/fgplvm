% DEMROBOTWIRELESS1 Wireless Robot data from University of Washington, without dynamics and without back constraints.


% Fix seeds
randn('seed', 1e5);
rand('seed', 1e5);

dataSetName = 'swissRoll';
experimentNo = 1;

% load data
[Y, lbls] = lvmLoadData(dataSetName);

% Set up model
options = fgplvmOptions('fitc');
options.back = 'linear';
options.backOptions = linearOptions;
options.optimiseInitBack = 1;
options.kern = 'gibbs';
latentDim = 2;
d = size(Y, 2);

model = fgplvmCreate(latentDim, d, Y, options);

% Optimise the model.
iters = 1000;
display = 1;

model = fgplvmOptimise(model, display, iters);

% Save the results.
capName = dataSetName;
capName(1) = upper(capName(1));
save(['dem' capName num2str(experimentNo) '.mat'], 'model');



% Load the results and display dynamically.
fgplvmResultsDynamic(dataSetName, experimentNo, 'vector')

