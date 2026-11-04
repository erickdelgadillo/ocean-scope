classdef TestIndependentCampaigns < matlab.unittest.TestCase
    properties (TestParameter)
        campaign = {'env2','env3'};
    end
    methods (Test)
        function archivalRegressionAndExports(test,campaign)
            root = fileparts(fileparts(mfilename('fullpath')));
            archive = fullfile(root,'..','coastal-upwelling-oceanography');
            day = 7; original = 1798; retained = 1790; stations = 10; cells = [2352,1544];
            if strcmp(campaign,'env3')
                day = 5; original = 1497; retained = 1497; stations = 9; cells = [2224,1466];
            end
            file = fullfile(archive,'data','longitudinal',sprintf('ctd_%s_d%d.xlsx',campaign,day));
            test.assumeTrue(isfile(file),'External archive required; buildtool validateAll requires all inputs.');
            oldPath = path; cleanup = onCleanup(@() path(oldPath));
            addpath(fullfile(root,'validation'));
            report = validate_campaign(campaign,archive);
            test.verifyNumElements(report.comparisons,12);
            ctd = report.comparisons(1:5); nutrients = report.comparisons(6:12);
            test.verifyEqual([ctd.original_samples],repmat(original,1,5));
            test.verifyEqual([ctd.longitude_positions],repmat(stations,1,5));
            test.verifyEqual([ctd.finite_cells],repmat(cells(1),1,5));
            test.verifyEqual([nutrients.finite_cells],repmat(cells(2),1,7));
            qc = [report.comparisons.qc];
            test.verifyEqual([qc.input_samples],[repmat(retained,1,5),repmat(20,1,7)]);
            test.verifyEqual([qc.unique_positions],[qc.input_samples]);
            test.verifyEqual([qc.duplicate_samples],zeros(1,12));
            test.verifyEqual([report.comparisons.nonfinite_samples],zeros(1,12));
            T = readtable(file,'VariableNamingRule','preserve');
            test.verifyEqual(unique(T.day),day);
            test.verifyNumElements(unique(T.st),stations);
            test.verifyNumElements(unique(T.Longitude),stations);
            configFile = fullfile(root,'configs',[campaign '.json']);
            config = jsondecode(fileread(configFile));
            before = cell(1,2);
            for k = 1:2
                source = fullfile(root,'configs',config.datasets(k).file);
                before{k} = oceanscope.file_hash(source);
            end
            manifest = run_oceanscope(configFile);
            test.verifyNumElements(manifest.outputs,12);
            test.verifyEqual(manifest.config_sha256,oceanscope.file_hash(configFile));
            test.verifyEqual(manifest.resolved_config,config);
            for k = 1:12
                entry = manifest.outputs(k);
                test.verifyTrue(isfile(entry.output));
                test.verifyEqual(entry.input_sha256,report.comparisons(k).input_sha256);
                test.verifyEqual(entry.input_sha256,oceanscope.file_hash(entry.input));
                saved = load(entry.numeric_output,'section');
                reference = load(fullfile(root,'results','validation',sprintf('%s_%s.mat',entry.dataset,entry.variable)));
                test.verifyEqual(saved.section.values,reference.actual.values);
                test.verifyEqual(saved.section.sample_mask,reference.valid);
            end
            for k = 1:2
                source = fullfile(root,'configs',config.datasets(k).file);
                test.verifyEqual(oceanscope.file_hash(source),before{k});
            end
        end
    end
end
