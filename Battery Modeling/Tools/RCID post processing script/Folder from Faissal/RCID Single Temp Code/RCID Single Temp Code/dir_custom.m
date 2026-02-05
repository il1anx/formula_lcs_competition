function listing = dir_custom(varargin)
% This function is a custom 'dir' function that automatically excludes
% the hidden '.' and '..' entries of the folder

if nargin == 0
    name = '.';
elseif nargin == 1
    name = varargin{1};
else
    error('Too many input arguments.')
end

listing = dir(name);

inds = [];
n    = 0;
k    = 1;

% If the name of any file in the directory is '.' or '..' it gets removed
% from the directory

while n < 2 && k <= length(listing)
    if any(strcmp(listing(k).name, {'.', '..'}))
        inds(end + 1) = k;
        n = n + 1;
    end
    k = k + 1;
end

listing(inds) = [];