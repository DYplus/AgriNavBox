function [data] = getDataFromTxt(filepath, rowRange, findchr)
% GETDATAFROMTXT 从固定格式的文本文件中读取数值矩阵并自动剔除首尾非数值列
% 
% 使用方法:
%   1. data = io.getDataFromTxt('path/to/file.txt');              % 读取全部有效行
%   2. data = io.getDataFromTxt('path/to/file.txt', [101, 900]);  % 读取第101到900条有效行
%   3. data = io.getDataFromTxt('path/to/file.txt', [], ';');     % 使用分号作为分隔符

    % -------------------------------
    % 参数处理
    % -------------------------------
    if nargin < 3 || isempty(findchr)
        findchr = ',';
    end
    if nargin < 2
        rowRange = []; 
    end

    % -------------------------------
    % 一次性读取整个文件
    % -------------------------------
    fid = fopen(filepath, 'r');
    if fid == -1, error('无法打开文件: %s', filepath); end
    % 按照换行符读取，保持原始行字符串
    content = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    lines = content{1};

    % -------------------------------
    % 众数统计（识别标准行长度）
    % -------------------------------
    % 统计每一行分隔符数量，用于过滤掉长度异常的干扰行
    rowLens = cellfun(@(s) sum(s == findchr), lines);
    if isempty(rowLens)
        data = []; return;
    end
    modal = mode(rowLens); 

    % -------------------------------
    % 过滤有效行并截取范围
    % -------------------------------
    % 仅保留分隔符数量等于众数的行
    validLineIdx = (rowLens == modal);
    lines = lines(validLineIdx);
    
    totalValidRows = length(lines);
    if totalValidRows == 0
        data = []; return;
    end

    % 确定实际需要解析的索引范围
    if isempty(rowRange)
        actualRange = 1:totalValidRows;
    else
        startIdx = max(1, rowRange(1));
        endIdx = min(totalValidRows, rowRange(2));
        actualRange = startIdx:endIdx;
    end
    
    lines = lines(actualRange);
    numToProcess = length(lines);
    
    % 预分配输出矩阵 (字段数 = 分隔符数 + 1)
    % 此时包含首列 $dg 和末列 *ed
    rawMatrix = zeros(numToProcess, modal + 1);

    % -------------------------------
    % 逐行转换为数值
    % -------------------------------
    for i = 1:numToProcess
        % 按分隔符拆分当前行
        str_split = strsplit(lines{i}, findchr);
        
        % 尝试转换每一个字段
        for j = 1:min(length(str_split), modal + 1)
            % 使用 str2double 转换，非数值（项首/项尾/乱码）会返回 NaN
            val = str2double(str_split{j});
            if ~isnan(val)
                rawMatrix(i, j) = val;
            end
        end
    end

    % -------------------------------
    % 剔除无效的首尾列并输出
    % -------------------------------
    % 逻辑：通常第一列是 $dg 标识符，最后一列是 *ed 校验位，均被转为了 0
    if size(rawMatrix, 2) >= 2
        data = rawMatrix(:, 2:end-1); 
    else
        data = rawMatrix;
    end
end

