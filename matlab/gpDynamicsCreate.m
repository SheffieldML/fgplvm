function model = gpDynamicsCreate(q, d, latentVals, options, diff, learn)

% GPDYNAMICSCREATE Create the dynamics model. 

% FGPLVM

if nargin < 6
  learn = 0;
  if nargin < 5
      diff = 1;
  end
end

X = latentVals(1:end-1, :);
y = latentVals(2:end, :);
if diff
  y = y - X;
end
model = gpCreate(q, d, X, y, options);

model.diff = diff;
model.learn = learn;
model.type = 'gpDynamics';
