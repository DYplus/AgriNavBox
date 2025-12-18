function [data] = getLogFromBin(filepath, saveMode)
% getLogFromBin - 严格对照 C 源码偏移量解析 ECU 二进制日志
%
% 使用方式:
%   data = getLogFromBin('14_054539.txt', 'csv');

    if nargin < 2, saveMode = false; end

    % 1. 读取原始二进制流
    fid = fopen(filepath, 'rb');
    if fid == -1, error('无法打开文件: %s', filepath); end
    raw = uint8(fread(fid, inf, 'uint8'));
    fclose(fid);

    % 2. 搜索同步头 0xAA 0x55 并验证报文 ID 0xEAF0
    % C代码逻辑: 找 0xAA 0x55，其后两个字节是 ID (EAF0)
    idxAA = find(raw(1:end-5) == 0xAA & raw(2:end-4) == 0x55);
    numPossible = length(idxAA);
    
    % 定义变量名 (严格对应 C 源码 sprintf 的 81 个输出位)
    varNames = {'year','month','day','hour','min','sec','msec',...
                'lat','lon','gga_fix','sats','hdop','alt','dgps_age','cors_id',...
                'vtg_azi','vtg_speed','vtg_fix','tra_azi','tra_roll','tra_fix','dis_cors',...
                'roll','pitch','azi','accx','accy','accz','gyrox','gyroy','gyroz','temp','gyro_w',...
                'gaussx','gaussy','eulerx','eulery','vspeed','perr','aerr','carrier_azi',...
                'ufbs','qw','est_fw','kf_fw','abline_azi','itoken','tra_kf','vtg_kf',...
                'motor_speed_cmd','motor_angle_cmd','curveptnum','onlinestate','nav_state','iot','differmode','abline_length',...
                'reg','imu','gnss','ab_ba','gyro','motor','encoder','lineshift',...
                'vol','rod_angle','rod_angle_raw','rms_f2','rms_f3',...
                'gyroangle','motorangle','rodangle','fcontrol_pluse','motorangletwo',...
                'statex','statexx','statexxx','Slave_GaussdX','Slave_GaussdY','steertimelog'};

    dataMatrix = nan(numPossible, length(varNames));
    validCount = 0;

    for i = 1:numPossible
        pos = idxAA(i);
        % 提取 ID (大端模式判断)
        msgID = double(raw(pos+2)) * 256 + double(raw(pos+3));
        if msgID ~= hex2dec('EAF0'), continue; end
        
        % p 为 Payload 起始位置 (对应 C 源码中的 &x_ptBuffer->cBuffer[6])
        p = pos + 6; 
        if p + 330 > length(raw), break; end 

        validCount = validCount + 1;
        
        % --- 以下偏移量完全对照 C 源码 log_process 函数 ---
        
        % 时间戳
        dataMatrix(validCount, 1)  = double(typecast(raw(p:p+1), 'int16'));   % [6] year
        dataMatrix(validCount, 2:6) = double(raw(p+2:p+6));                  % [8..12] month..sec
        dataMatrix(validCount, 7)  = double(typecast(raw(p+7:p+8), 'int16')); % [13] msec

        % 定位数据
        dataMatrix(validCount, 8)  = typecast(raw(p+9:p+16), 'double');      % [15] lat
        dataMatrix(validCount, 9)  = typecast(raw(p+17:p+24), 'double');     % [23] lon
        dataMatrix(validCount, 10) = double(raw(p+25));                      % [31] gga_fix
        dataMatrix(validCount, 11) = double(raw(p+26));                      % [32] sats
        dataMatrix(validCount, 12) = typecast(raw(p+27:p+30), 'single');     % [33] hdop
        dataMatrix(validCount, 13) = typecast(raw(p+31:p+34), 'single');     % [37] altitude
        dataMatrix(validCount, 14) = double(typecast(raw(p+35:p+36), 'int16')); % [41] dgps_age
        dataMatrix(validCount, 15) = double(typecast(raw(p+37:p+38), 'int16')); % [43] cors_id

        % VTG & TRA (注意 C 源码此处偏移有跳跃)
        dataMatrix(validCount, 16) = typecast(raw(p+39:p+42), 'single');     % [45] vtg_azi
        dataMatrix(validCount, 17) = typecast(raw(p+43:p+46), 'single');     % [49] vtg_speed
        dataMatrix(validCount, 18) = double(raw(p+47));                      % [53] vtg_fix
        dataMatrix(validCount, 19) = typecast(raw(p+48:p+51), 'single');     % [54] tra_azi
        dataMatrix(validCount, 20) = typecast(raw(p+52:p+55), 'single');     % [58] tra_roll
        dataMatrix(validCount, 21) = double(raw(p+56));                      % [62] tra_fix
        dataMatrix(validCount, 22) = typecast(raw(p+57:p+60), 'single');     % [63] dis_cors

        % IMU 
        dataMatrix(validCount, 23:31) = reshape(typecast(raw(p+61:p+96), 'single'), 1, []); % [67..99] roll..gyroz
        dataMatrix(validCount, 32) = typecast(raw(p+97:p+100), 'single');    % [103] temp
        dataMatrix(validCount, 33) = typecast(raw(p+101:p+104), 'single');   % [107] gyro_w (fGyroz2)

        % 算法中间量 (Double 精度)
        dataMatrix(validCount, 34) = typecast(raw(p+105:p+112), 'double');   % [111] gaussx
        dataMatrix(validCount, 35) = typecast(raw(p+113:p+120), 'double');   % [119] gaussy
        dataMatrix(validCount, 36) = typecast(raw(p+121:p+128), 'double');   % [127] eulerx
        dataMatrix(validCount, 37) = typecast(raw(p+129:p+136), 'double');   % [135] eulery
        
        % 控制/状态
        dataMatrix(validCount, 38:41) = reshape(typecast(raw(p+137:p+152), 'single'), 1, []); % [143..155] vspeed..carrier_azi
        dataMatrix(validCount, 42) = double(raw(p+153));                     % [159] ufbs
        dataMatrix(validCount, 43:46) = reshape(typecast(raw(p+154:p+169), 'single'), 1, []); % [160..172] qw..abline_azi
        dataMatrix(validCount, 47) = double(typecast(raw(p+170:p+173), 'int32')); % [176] itoken
        dataMatrix(validCount, 48:51) = reshape(typecast(raw(p+174:p+189), 'single'), 1, []); % [180..192] tra_kf..motor_angle_cmd
        dataMatrix(validCount, 52) = double(typecast(raw(p+190:p+193), 'int32')); % [196] curveptnum
        dataMatrix(validCount, 53:56) = double(raw(p+194:p+197));            % [200..203] onlinestate..differmode
        dataMatrix(validCount, 57) = typecast(raw(p+198:p+201), 'single');   % [204] ab_length
        dataMatrix(validCount, 58:63) = double(raw(p+202:p+207));            % [208..213] alive flags
        
        dataMatrix(validCount, 64) = typecast(raw(p+208:p+215), 'double');   % [214] encoder
        dataMatrix(validCount, 65) = typecast(raw(p+216:p+219), 'single');   % [222] lineshift
        
        % Reserve 字段
        dataMatrix(validCount, 66) = typecast(raw(p+220:p+223), 'single');   % [226] fReserve1 (vol)
        dataMatrix(validCount, 67) = typecast(raw(p+224:p+227), 'single');   % [230] fReserve2 (rod_angle)
        dataMatrix(validCount, 68) = typecast(raw(p+228:p+231), 'single');   % [234] fReserve3 (rod_angle_raw)
        dataMatrix(validCount, 69) = double(raw(p+232));                     % [238] uReserve1
        dataMatrix(validCount, 70) = double(raw(p+233));                     % [239] uReserve2
        
        % 映射 C++ sprintf 尾部的特定 Reserve 字段
        dataMatrix(validCount, 71) = typecast(raw(p+278:p+281), 'single');   % [284] fReserve9 -> gyroangle
        dataMatrix(validCount, 72) = typecast(raw(p+282:p+285), 'single');   % [288] fReserve10 -> motorangle
        dataMatrix(validCount, 73) = typecast(raw(p+286:p+289), 'single');   % [292] fReserve11 -> rodangle
        dataMatrix(validCount, 74) = typecast(raw(p+266:p+269), 'single');   % [272] fcontrol_pluse
        dataMatrix(validCount, 75) = typecast(raw(p+290:p+293), 'single');   % [296] fReserve12 -> motorangletwo
        dataMatrix(validCount, 76) = typecast(raw(p+294:p+301), 'double');   % [300] fReserve13 -> statex
        dataMatrix(validCount, 77) = typecast(raw(p+302:p+309), 'double');   % [308] fReserve15 -> statexx
        dataMatrix(validCount, 78) = typecast(raw(p+310:p+317), 'double');   % [316] fReserve17 -> statexxx
        dataMatrix(validCount, 79) = typecast(raw(p+318:p+321), 'single');   % [324] fReserve19 -> Slave_GaussdX
        dataMatrix(validCount, 80) = typecast(raw(p+322:p+325), 'single');   % [328] fReserve20 -> Slave_GaussdY
        dataMatrix(validCount, 81) = typecast(raw(p+274:p+277), 'single');   % [280] fReserve8 -> steertimelog
    end

    % 3. 数据收缩与过滤
    if validCount > 0
        dataMatrix = dataMatrix(1:validCount, :);
        data = array2table(dataMatrix, 'VariableNames', varNames);
        % 过滤掉异常年份 (根据C程序逻辑，未对年份做强制过滤，但这里保留以增强鲁棒性)
        data = data(data.year >= 2000 & data.year <= 2100, :);
        fprintf('解析完成: 共提取 %d 帧数据。\n', height(data));
    else
        data = table();
        warning('未发现有效的 EAF0 报文。');
    end

    % 4. 保存
if ischar(saveMode) || isstring(saveMode)
        [fDir, fName, ~] = fileparts(filepath);
        outPath = fullfile(fDir, [fName, '_parsed.', lower(saveMode)]);
        
        % 确定分隔符：CSV用逗号，TXT用制表符
        if strcmpi(saveMode, 'csv')
            delim = ','; 
        else
            delim = '\t'; 
        end
        
        % 打开文件写入
        fidOut = fopen(outPath, 'w');
        if fidOut == -1, error('无法创建输出文件'); end
        
        % --- 修复后的表头写入逻辑 ---
        % 使用 strjoin 动态生成表头字符串，确保分隔符一致且没有多余的反斜杠
        headerStr = strjoin(varNames, delim);
        fprintf(fidOut, '%s\n', headerStr);
        
        % --- 构造每一行的格式字符串 ---
        % 生成类似 %.8f\t%.8f\t... 的格式
        rowFormat = ['%.8f', repmat([delim, '%.8f'], 1, length(varNames)-1), '\n'];
        
        % 批量写入数据 (转置矩阵以匹配 fprintf 的列优先顺序)
        fprintf(fidOut, rowFormat, dataMatrix');
        
        fclose(fidOut);
        fprintf('解析成功: %d 帧。数据已保存至: %s\n', size(dataMatrix,1), outPath);
    end
end

