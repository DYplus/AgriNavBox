function [finalTable] = getKeyValueFromTxt(filepath, rowRange, findchr)
% GETKEYVALUEFROMTXT 读取键值对日志并支持行数截取
% 
% 使用方法:
%   1. data = io.getKeyValueFromTxt('Data/9.1.txt');            % 全部读取
%   2. data = io.getKeyValueFromTxt('Data/9.1.txt', [1, 500]);  % 只读前500行
%   3. data = io.getKeyValueFromTxt('Data/9.1.txt', [5000, 10000]); % 读中间段

    % -------------------------------
    % 参数处理
    % -------------------------------
    if nargin < 3 || isempty(findchr), findchr = ','; end
    if nargin < 2, rowRange = []; end

    % 1. 读取文件
    fid = fopen(filepath, 'r');
    if fid == -1, error('无法打开文件: %s', filepath); end
    content = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    lines = content{1};

    % 过滤非有效行（必须以 $ 开头）
    validIdx = startsWith(lines, '$');
    lines = lines(validIdx);
    totalValidRows = length(lines);

    if totalValidRows == 0, finalTable = table(); return; end

    % -------------------------------
    % 第一步：探测模式（扫描前 10 行）
    % -------------------------------
    scanLimit = min(10, totalValidRows);
    headerPool = {};
    maxFieldCount = 0;
    
    for i = 1:scanLimit
        tokens = strsplit(lines{i}, findchr);
        if numel(tokens) < 3, continue; end
        keys = tokens(2:2:end); 
        validKeys = matlab.lang.makeValidName(keys);
        if numel(validKeys) > maxFieldCount
            maxFieldCount = numel(validKeys);
            headerPool = matlab.lang.makeUniqueStrings(validKeys);
        end
    end

    % -------------------------------
    % 第二步：截取行数范围
    % -------------------------------
    if isempty(rowRange)
        actualRange = 1:totalValidRows;
    else
        startIdx = max(1, rowRange(1));
        endIdx = min(totalValidRows, rowRange(2));
        actualRange = startIdx:endIdx;
    end
    
    lines = lines(actualRange);
    numToProcess = length(lines);
    
    % -------------------------------
    % 第三步：建立映射并快速填充
    % -------------------------------
    numFields = numel(headerPool);
    fieldMap = containers.Map(headerPool, 1:numFields);
    dataMatrix = nan(numToProcess, numFields); 

    for i = 1:numToProcess
        tokens = strsplit(lines{i}, findchr);
        % 解析键值对填充矩阵
        for k = 2:2:numel(tokens)-1
            key = matlab.lang.makeValidName(tokens{k});
            if isKey(fieldMap, key)
                val = str2double(tokens{k+1});
                dataMatrix(i, fieldMap(key)) = val;
            end
        end
    end

    % -------------------------------
    % 第四步：封装输出
    % -------------------------------
    finalTable = array2table(dataMatrix, 'VariableNames', headerPool);
    fprintf('解析完成！截取范围: [%d - %d], 字段数: %d\n', ...
            actualRange(1), actualRange(end), numFields);
end

