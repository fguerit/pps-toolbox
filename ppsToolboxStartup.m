%startup file for the pps toolbox

% Add source folders to the path
[current_path, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(current_path, 'source')))
fprintf('\nPPS toolbox loaded.\n')

clear current_path
