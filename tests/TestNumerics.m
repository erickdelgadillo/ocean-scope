classdef TestNumerics < matlab.unittest.TestCase
    methods (Test)
        function planeAndHull(test)
            T = table([0;1;0;1],[0;0;0;0],[0;0;10;10],[2;5;22;25], ...
                'VariableNames',{'lon','lat','depth','value'});
            d = struct('columns',struct('longitude','lon','latitude','lat','depth','depth'), ...
                'max_depth',15,'interpolation',struct('horizontal_points',3,'depth_start',0,'depth_step',5));
            s = oceanscope.interpolate_section(T,d,struct('id','test','column','value'));
            expected = 2+3*s.X/max(s.x)+2*s.Z;
            test.verifyEqual(s.values(1:3,:),expected(1:3,:),'AbsTol',1e-12);
            test.verifyTrue(all(isnan(s.values(4,:))));
        end
        function fixedOriginWithMissingEndpoint(test)
            g = struct('origin_longitude',8.9145,'origin_latitude','median');
            d = oceanscope.coastal_distance([9.1;9.3],[42;42],g);
            test.verifyGreaterThan(d(1),0);
            signed = g; signed.origin_longitude = -8.9145;
            test.verifyEqual(d,oceanscope.coastal_distance([-9.1;-9.3],[42;42],signed));
        end
        function rejectsCollinear(test)
            T = table([0;1;2],[0;0;0],[0;1;2],[1;2;3], ...
                'VariableNames',{'lon','lat','depth','value'});
            d = struct('columns',struct('longitude','lon','latitude','lat','depth','depth'),'max_depth',5);
            test.verifyError(@() oceanscope.interpolate_section(T,d,struct('id','test','column','value')), ...
                'OceanScope:DegenerateGrid');
        end
        function rejectsInvalidGrid(test)
            root = fileparts(fileparts(mfilename('fullpath')));
            c = jsondecode(fileread(fullfile(root,'configs','demo.json'))); d = c.datasets;
            T = oceanscope.read_data(fullfile(root,'examples','synthetic_ctd.csv'),d);
            d.interpolation = struct('typo',3);
            test.verifyError(@() oceanscope.interpolate_section(T,d,d.variables(1)),'OceanScope:InvalidConfig');
        end
        function missingObservationsAndCustomGrid(test)
            T = table([0;1;0;1;0;NaN;0;0;0],zeros(9,1), ...
                [0;0;10;10;0;5;NaN;-1;20],[2;5;22;25;NaN;7;7;7;7], ...
                'VariableNames',{'lon','lat','depth','value'});
            original = T;
            d = struct('columns',struct('longitude','lon','latitude','lat','depth','depth'), ...
                'max_depth',10,'geometry',struct('origin_longitude',0,'origin_latitude',0), ...
                'interpolation',struct('horizontal_points',7,'depth_start',2,'depth_step',3));
            s = oceanscope.interpolate_section(T,d,struct('id','test','column','value'));
            test.verifyEqual(s.sample_mask,[true(4,1);false(5,1)]);
            test.verifyEqual(s.qc.excluded_samples,5);
            test.verifyEqual(s.qc.duplicate_samples,0);
            test.verifySize(s.values,[3,7]);
            test.verifyEqual(s.Z(:,1),[2;5;8]);
            test.verifyEqual(s.values,2+3*s.X/max(s.x)+2*s.Z,'AbsTol',1e-12);
            test.verifyEqual(T,original);
        end
        function env1Regression(test)
            root = fileparts(fileparts(mfilename('fullpath')));
            archive = fullfile(root,'..','coastal-upwelling-oceanography');
            test.assumeTrue(isfile(fullfile(archive,'data','longitudinal','ctd_env1_d7.xlsx')), ...
                'External historical archive required; run buildtool validate to require it.');
            oldPath = path; cleanup = onCleanup(@() path(oldPath));
            addpath(fullfile(root,'validation'));
            report = validate_env1(archive);
            test.verifyNumElements(report.comparisons,12);
            test.verifyEqual([report.comparisons.finite_cells],[repmat(2353,1,5),repmat(1603,1,7)]);
            test.verifyEqual([report.comparisons(1:5).original_samples],repmat(1763,1,5));
            qc = [report.comparisons(1:5).qc];
            test.verifyEqual([qc.input_samples],repmat(1762,1,5));
            test.verifyEqual([qc.unique_positions],repmat(1761,1,5));
            qc = [report.comparisons(6:12).qc];
            test.verifyEqual([qc.input_samples],repmat(20,1,7));
            test.verifyEqual([qc.duplicate_samples],zeros(1,7));
        end
    end
end
