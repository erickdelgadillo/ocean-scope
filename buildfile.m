function plan = buildfile
%BUILDFILE Local MATLAB Build Tool tasks. Requires MATLAB R2022b+.
plan = buildplan(localfunctions);
plan.DefaultTasks = "test";
end

function testTask(~)
root = fileparts(mfilename('fullpath'));
addpath(root);
results = runtests(fullfile(root,'tests'));
assertSuccess(results);
end

function demoTask(~)
root = fileparts(mfilename('fullpath'));
addpath(root);
run_oceanscope(fullfile(root,'configs','demo.json'));
end
