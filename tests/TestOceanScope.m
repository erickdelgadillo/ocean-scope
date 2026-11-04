classdef TestOceanScope < matlab.unittest.TestCase
    methods (Test)
        function coastalEndpoint(testCase)
            d = oceanscope.coastal_distance([8.91;9.1;9.3],[42;42;42]);
            testCase.verifyEqual(d(1),0,'AbsTol',1e-10);
            testCase.verifyGreaterThan(d(3),d(2));
        end
        function geometryRejectsMissing(testCase)
            testCase.verifyError(@() oceanscope.coastal_distance([NaN;NaN],[42;42]), ...
                'OceanScope:MissingCoordinates');
        end
        function demoGeneratesFigures(testCase)
            repo = fileparts(fileparts(mfilename('fullpath')));
            manifest = run_oceanscope(fullfile(repo,'configs','demo.json'));
            testCase.verifyNumElements(manifest.outputs,2);
            testCase.verifyTrue(isfile(manifest.outputs(1).output));
            testCase.verifyTrue(isfile(manifest.outputs(2).output));
            testCase.verifyEqual(manifest.config_sha256,oceanscope.file_hash(manifest.config));
            testCase.verifyEqual(manifest.resolved_config,jsondecode(fileread(manifest.config)));
            testCase.verifyEqual(manifest.matlab_version,version);
            for entry = manifest.outputs
                testCase.verifyEqual(entry.input_sha256,oceanscope.file_hash(entry.input));
                saved = load(entry.numeric_output,'section');
                testCase.verifyEqual(saved.section.qc,entry.qc);
                testCase.verifyEqual(nnz(saved.section.sample_mask),entry.valid_samples);
            end
            for entry = manifest.code_sha256
                file = fullfile(repo,'+oceanscope',entry.file);
                if strcmp(entry.file,'run_oceanscope.m'), file = fullfile(repo,entry.file); end
                testCase.verifyEqual(entry.sha256,oceanscope.file_hash(file));
            end
        end
        function duplicateCoordinatesAreAveraged(testCase)
            [x,z,y,qc] = oceanscope.aggregate_duplicates( ...
                [1;1;2;2], [10;10;20;30], [12.992;12.994;5;7]);
            testCase.verifyEqual(x,[1;2;2]);
            testCase.verifyEqual(z,[10;20;30]);
            testCase.verifyEqual(y,[12.993;5;7],'AbsTol',1e-12);
            testCase.verifyEqual(qc.input_samples,4);
            testCase.verifyEqual(qc.unique_positions,3);
            testCase.verifyEqual(qc.duplicate_groups,1);
            testCase.verifyEqual(qc.duplicate_samples,1);
        end
        function noDuplicatesRemainUnchanged(testCase)
            [x,z,y,qc] = oceanscope.aggregate_duplicates( ...
                [0;1;2], [0;10;20], [14;15;16]);
            testCase.verifyEqual([x,z,y],[0 0 14;1 10 15;2 20 16]);
            testCase.verifyEqual(qc.duplicate_samples,0);
            testCase.verifyEqual(qc.duplicate_groups,0);
        end
        function rejectsInvalidAggregationInputs(testCase)
            testCase.verifyError(@() oceanscope.aggregate_duplicates( ...
                [1;1],[10;10],[4;NaN]),'OceanScope:InvalidSamples');
        end
        function demoManifestIncludesDuplicateQC(testCase)
            repo = fileparts(fileparts(mfilename('fullpath')));
            manifest = run_oceanscope(fullfile(repo,'configs','demo.json'));
            testCase.verifyEqual(manifest.outputs(1).qc.duplicate_samples,0);
            testCase.verifyEqual(manifest.outputs(2).qc.duplicate_groups,0);
        end
        function missingInputsFail(testCase)
            d = struct('columns',struct('longitude','x','latitude','y','depth','z'), ...
                'variables',struct('id','temperature','column','temp'));
            testCase.verifyError(@() oceanscope.read_data('missing-file.csv',d), ...
                'OceanScope:MissingInput');
        end
    end
end
