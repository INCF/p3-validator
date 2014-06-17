function v = env_version
% Get the current version of BCILAB
v = '1.0';
if isdeployed
    v = [v ' compiled']; end
