function [Y, YRank] = pySlice(X, dim, startInd, endInd, step, removeDim, XRank)
%PYSLICE Slices a tensor from 'start' to 'end' in intervals of 'step'.
% slice.Tensor(Tensor(a) self, int dim=0, SymInt? start=None, SymInt? end=None, SymInt step=1) -> Tensor(a)

%   Copyright 2025 The MathWorks, Inc.

import soc_model.ops.*


% Slice the data
% Set default Axes and Steps if not supplied
if isempty(dim)
    dim = 0:XRank-1;   % All axes
end
if any(dim<0)
    dim(dim<0) = dim(dim<0) + XRank; % Handle negative Axes.
end
if isempty(step)
    step = ones(1, numel(startInd));
end
% Init all dims to :
S.subs = repmat({':'}, 1, XRank);
S.type = '()';

%Convert dim to reverse-Python dimension
RevDim = XRank - dim;

% Set Starts and Ends for each axis
for i = 1:numel(RevDim)
    %     DLTDim = Xrank - dim(i);                                               % The DLT dim is the reverse of the ONNX dim.

    %In scripted models, startInd/endInd could be empty (optional). In such
    %cases we set startInd to 0 and endInd to number of elements in the
    %dimension
    if isempty(startInd)
        startInd(i) = 0;
    end

    if isempty(endInd)
        endInd(i) = size(X,RevDim(i));
    end

    % "If a negative value is passed for any of the start or end indices,
    % it represents number of elements before the end of that dimension."
    if startInd(i) < 0
        startInd(i) = size(X,RevDim(i)) + startInd(i);
    end
    if endInd(i) < 0
        endInd(i) = max(-1, size(X,RevDim(i)) + endInd(i));                        % The -1 case is when we're slicing backward and want to include 0.
    end

    % If called for 'Select' operator, set endInd+1
    if removeDim
        endInd(i) = endInd(i) + 1;
    end

    % "If the value passed to start or end is larger than the n (the number
    % of elements in this dimension), it represents n."
    if startInd(i) > size(X,RevDim(i))
        startInd(i) = size(X,RevDim(i));
    end
    if endInd(i) > size(X,RevDim(i))
        endInd(i) = size(X,RevDim(i));
    end
    if step(i) > 0
        S.subs{RevDim(i)} = 1 + (startInd(i) : step(i) : endInd(i)-1);            % 1 + (Origin 0 indexing with end index excluded)
    else
        S.subs{RevDim(i)} = 1 + (startInd(i) : step(i) : endInd(i)+1);            % 1 + (Origin 0 indexing with end index excluded)
    end
end
Y = subsref(X, S);

%Condition for select operation, remove selected dimension and reduce rank
if removeDim
    YRank = XRank - 1;
    YvalSize = [size(Y), ones(1, XRank - ndims(Y))];
    if(all(YvalSize(RevDim) == 1))
        YvalSize(RevDim) = [];
        Y = reshape(Y,YvalSize);
    end
else
    YRank = XRank;
end

label = repelem('U',YRank);
Y = dlarray(Y, label);
end