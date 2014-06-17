function [S,lam] = cov_shrink(X,w)
% Estimate the covariance matrix for some data using analytical shrinkage.
% Sigma = cov_shrink(X,w)
%
% This gives robust estimates even when the ratio of number of observations to number of variables is very low. [1]
%
% X is a matrix where each row is an observation, and each column is a 
% variable. The mean is removed from each column before calculating the
% result. The estimate is unbiased, i.e. cov_shrink normalizes by N-1.
%
% w is an optional [Nx1] vector of nonnegative weights.
%
% See also: 
%   cov, mean
%
% Dependencies: 
%   bsxfun
%
% References:
%   [1] J. Schaefer and K. Strimmer,
%       "A shrinkage approach to large-scale covariance matrix estimation and implications for functional genomics." 
%       Statist. Appl. Genet. Mol. Biol. 4:32.
% 
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-04-03

mem_quota = 0.2;        % use at most this fraction of the free memory for temp data
block_increment = 1.5;  % consider incrementally larger numbers of blocks (incremented by this factor)

[n,p] = size(X);
if nargin < 2
    w = ones(n,1)/n;
else
    w = w/sum(w);
end

S = var(X,w);
if p ~= 1
    scale = diag(sqrt(S));
    % center & standardize
    X = bsxfun(@minus,X,sum(bsxfun(@times,X,w)));
    X = bsxfun(@times,X,(n-1)./(n*std(X,w)));
    % the following computation can be quite memory intensive; do it in successively smaller blocks (if it fails)...
    VR = zeros(p);
    R = zeros(p);
    % calc candidate data partitionings
    tryblocks = ceil(block_increment.^(0:p));
    % calc according temporary data sizes in bytes
    trysizes = size(X,1)*(ceil(p./tryblocks)).^2*8;
    % try only those that would fit within the free-memory quota...
    try
        bean = java.lang.management.ManagementFactory.getOperatingSystemMXBean();
        mem_free = bean.getFreePhysicalMemorySize();
    catch
        mem_free = 1e10; % make a fairly conservative assumption
    end
    for blocks = tryblocks(trysizes <= mem_free*mem_quota)        
        % 2d block length
        blen = ceil(p/blocks);
        % pad X with zeros
        X(:,end+1:blen*blocks) = 0;
        try
            for bx = 0:blocks-1
                for by = 0:blocks-1
                    ix = 1+bx*blen : blen+bx*blen;
                    iy = 1+by*blen : blen+by*blen;
                    % calc a block of the sample covariance tensor
                    B = repmat(reshape(X(:,ix)',[length(ix) 1 n]),[1 length(ix) 1]) .* repmat(reshape(X(:,iy)',[1 length(iy) n]), [length(iy) 1 1]);
                    % calc a block of the per-element weighted variance of the correlation matrix
                    VR(ix,iy) = var(B,w,3)*n^2/((n-1)^3);
                    % and calc a block of the mean of the correlation matrix
                    R(ix,iy) = sum(bsxfun(@times,permute(w,[3 2 1]),B),3)*n/(n-1);
                end
            end
            % remove zeros
            VR = VR(1:p,1:p);
            R = R(1:p,1:p);
            % success...
            break;
         catch
            % out of memory, start again
         end
    end
    % calc shrinkage parameter
    lam = max(0,min(1,sum(sum(tril(VR,-1)))/sum(sum(tril(R,-1).^2))));
    % calc correlation matrix with shrinkage
    R = (1-lam)*R;
    R(logical(eye(p))) = 1;
    % scale back to covariance matrix
    S = scale*R*scale;
else
    lam = 0;
end
