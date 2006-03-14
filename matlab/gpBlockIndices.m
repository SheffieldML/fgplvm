function ind = gpBlockIndices(model, blockNo)

% GPBLOCKINDICES Return indices of given block.

% FGPLVM


if ~strcmp(model.approx, 'pitc')
  error('Block indices only relevant for pitc approximation.');
else
  if blockNo == 1
    startVal = 1;
  else
    startVal = model.blockEnd(blockNo-1)+1;
  end
  endVal = model.blockEnd(blockNo);
  ind = startVal:endVal;
end