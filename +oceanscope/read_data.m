function T = read_data(path, dataset)
%READ_DATA Import source data with source-column names preserved.
path = string(path);
if ~isfile(path)
    error('OceanScope:MissingInput','Input not found: %s',path);
end
[~,~,ext] = fileparts(path);
switch lower(ext)
    case '.csv'
        if isfield(dataset,'delimiter')
            opts = detectImportOptions(path,'Delimiter',char(string(dataset.delimiter)), ...
                'VariableNamingRule','preserve');
            T = readtable(path,opts);
        else
            T = readtable(path,'VariableNamingRule','preserve');
        end
    case {'.xlsx','.xls'}
        T = readtable(path,'VariableNamingRule','preserve');
    otherwise
        error('OceanScope:UnsupportedInput','Unsupported file type: %s',ext);
end
columns = dataset.columns;
required = [string(columns.longitude),string(columns.latitude),string(columns.depth)];
variables = dataset.variables;
if iscell(variables), variables = [variables{:}]; end
for i = 1:numel(variables)
    required(end+1) = string(variables(i).column); %#ok<AGROW>
end
missing = setdiff(required,string(T.Properties.VariableNames));
if ~isempty(missing)
    error('OceanScope:MissingColumn','Missing input columns: %s',strjoin(missing,', '));
end
for col = required
    if ~isnumeric(T.(col))
        error('OceanScope:NonNumericColumn','Expected numeric column: %s',col);
    end
end
end
