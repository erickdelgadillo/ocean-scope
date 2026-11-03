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
        end
        function missingInputsFail(testCase)
            d = struct('columns',struct('longitude','x','latitude','y','depth','z'), ...
                'variables',struct('id','temperature','column','temp'));
            testCase.verifyError(@() oceanscope.read_data('missing-file.csv',d), ...
                'OceanScope:MissingInput');
        end
    end
end
