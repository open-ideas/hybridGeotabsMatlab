function [ variable ] = findOutput( filename, variablename )
%FINDOUTPUTFUNC Finds an output from a Dymola outputfile
% first input: name of the datafile  
% second input: name of the variable

load(filename)          % name of the saved file

name2 = name';               % twist for right spelling

position = 0;

for i = 1: length(name2(:,1))
    
    found = strcmp(strtrim(name2(i,:)),variablename);

    if found
        position = i;
    end
    
end

if position ==0
    str = sprintf('Variable %s not found in %s', variablename{1} , filename);
    error(str)
end

typeVar = abs(dataInfo(1,position));
sec_position = abs(dataInfo(2,position));

if typeVar == 1 % parameter
    var = data_1(sec_position,:);
    variable = var(1).*ones(1,size(data_2,2));
elseif typeVar == 2 || typeVar == 0
    variable = data_2(sec_position,:);
end

end

