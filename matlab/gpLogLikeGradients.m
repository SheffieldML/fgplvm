function [gParam, gX_u, gX] = gpLogLikeGradients(model, ...
                                                  X, Y, X_u)

% GPLOGLIKEGRADIENTS Compute the gradients for the parameters and X.

% FGPLVM

if nargin < 4
  if isfield(model, 'X_u')
    X_u = model.X_u;
  else
    X_u = [];
  end
  if nargin < 3
    Y = model.Y;
  end
  if nargin < 2
    X = model.X;
  end
end

gX_u = [];
gX = [];

switch model.approx
 case 'ftc'
  % Full training conditional.
  
  if nargout > 1    
    %%% Prepare to Compute Gradients with respect to X %%%
    gKX = kernGradX(model.kern, X, X);
    gKX = gKX*2;
    dgKX = kernDiagGradX(model.kern, X);
    for i = 1:model.N
      gKX(i, :, i) = dgKX(i, :);
    end
    gX = zeros(model.N, model.q);
  end
  
  %%% Compute Gradients of Kernel Parameters %%%
  gParam = zeros(1, model.kern.nParams);

  for k = 1:model.d
    gK = localCovarianceGradients(model, Y(:, k));
    if nargout > 1
      %%% Compute Gradients with respect to X %%%
      for i = 1:model.N
        for j = 1:model.q
          gX(i, j) = gX(i, j) + gKX(:, j, i)'*gK(:, i);
        end
      end
    end
    %%% Compute Gradients of Kernel Parameters %%%
    gParam = gParam + kernGradient(model.kern, X, gK);
  end
 
 case {'dtc', 'fitc', 'pitc'}
  % Sparse approximations.
  [gK_u, gK_uf, gK_star, g_sigma2] = gpCovGrads(model, Y);
  
  %%% Compute Gradients of Kernel Parameters %%%
  gParam_u = kernGradient(model.kern, X_u, gK_u);
  gParam_uf = kernGradient(model.kern, X_u, X, gK_uf);
  g_param = gParam_u + gParam_uf;
  
  %%% Compute Gradients with respect to X_u %%%
  gKX = kernGradX(model.kern, X_u, X_u);
  
  % The 2 accounts for the fact that covGrad is symmetric
  gKX = gKX*2;
  dgKX = kernDiagGradX(model.kern, X_u);
  for i = 1:model.k
    gKX(i, :, i) = dgKX(i, :);
  end
  
  % Allocate space for gX_u
  gX_u = zeros(model.k, model.q);
  % Compute portion associated with gK_u
  for i = 1:model.k
    for j = 1:model.q
      gX_u(i, j) = gKX(:, j, i)'*gK_u(:, i);
    end
  end

  % Compute portion associated with gK_uf
  gKX_uf = kernGradX(model.kern, X_u, X);
  for i = 1:model.k
    for j = 1:model.q
      gX_u(i, j) = gX_u(i, j) + gKX_uf(:, j, i)'*gK_uf(i, :)';
    end
  end

  if nargout > 1
    %%% Compute gradients with respect to X %%%
    
    % Allocate space for gX
    gX = zeros(model.N, model.q);
    
    % this needs to be recomputed so that it is wrt X not X_u
    gKX_uf = kernGradX(model.kern, X, X_u);
    
    for i = 1:model.N
      for j = 1:model.q
        gX(i, j) = gKX_uf(:, j, i)'*gK_uf(:, i);
      end
    end    
  end
 otherwise
  error('Unknown model approximation.')
end

switch model.approx
 case 'ftc'
  % Full training conditional. Nothing required here.
 case 'dtc'
  % Deterministic training conditional.  

  % append sigma2 gradient to end of parameters
  gParam = [g_param(:)' g_sigma2];
 
 case 'fitc'
  % Fully independent training conditional.
  
  if nargout > 1
    % deal with diagonal term's effect on X gradients..
    gKXdiag = kernDiagGradX(model.kern, X);
    for i = 1:model.N
      gX(i, :) = gX(i, :) + gKXdiag(i, :)*gK_star(i);
    end
  end
  
  % deal with diagonal term's affect on kernel parameters.
  for i = 1:model.N
    g_param = g_param ...
              + kernGradient(model.kern, X(i, :), gK_star(i));
  end

  % append sigma2 gradient to end of parameters  
  gParam = [g_param(:)' g_sigma2];

 case 'pitc'
  % Partially independent training conditional.
  
  if nargout > 1
    % deal with block diagonal term's effect on X gradients.
    startVal = 1;
    for i = 1:length(model.blockEnd)
      endVal = model.blockEnd(i);
      ind = startVal:endVal;
      gKXblock = kernGradX(model.kern, X(ind, :), X(ind, :));
      
      % The 2 accounts for the fact that covGrad is symmetric
      gKXblock = gKXblock*2;
      
      % fix diagonal
      dgKXblock = kernDiagGradX(model.kern, X(ind, :));
      for j = 1:length(ind)
        gKXblock(j, :, j) = dgKXblock(j, :);
      end
      
      for j = ind
        for k = 1:model.q
          subInd = j - startVal + 1;
          gX(j, k) = gX(j, k) + gKXblock(:, k, subInd)'*gK_star{i}(:, subInd);
        end
      end
      startVal = endVal + 1;
    end
  end
  % deal with block diagonal's effect on kernel parameters.
  startVal = 1;
  for i = 1:length(model.blockEnd);
    endVal = model.blockEnd(i);
    ind = startVal:endVal;
    g_param = g_param ...
              + kernGradient(model.kern, X(ind, :), gK_star{i});
    startVal = endVal + 1;
  end

  % append sigma2 gradient to end of parameters
  gParam = [g_param(:)' g_sigma2];

 otherwise
  error('Unrecognised model approximation');
end

% if there is only one output argument, pack gX_u and gParam into it.
if nargout == 1;
  gParam = [gX_u(:)' gParam];
end

function gK = localCovarianceGradients(model, y, dimension)

% FGPLVMCOVARIANCEGRADIENTS

invKy = model.invK_uu*y;
gK = -model.invK_uu + invKy*invKy';
gK = gK*.5;