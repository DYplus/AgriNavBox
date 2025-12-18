%% AgriNavBox IMU 零偏处理流程
% 1. 设置文件路径
dataDir = 'Data'; % 根据截图，数据在 Data 文件夹下
fileName = '静止数据.xlsx';
fullPath = fullfile(dataDir, fileName);

% 2. 提取数据 (假设前 500 行是完全静止的)
% 读取 13-15 列: XYZ轴角速度 (Gyro)
% 读取 16-18 列: XYZ轴加速度 (Acc)
staticRange = 'M200:R2000'; % M-O列是13-15, P-R列是16-18
imuStatic = readmatrix(fullPath, 'Range', staticRange);

gyroData = imuStatic(:, 1:3); % 对应原表的 13, 14, 15 列
accData  = imuStatic(:, 4:6); % 对应原表的 16, 17, 18 列

% 3. 调用工具箱函数计算零偏
[gb, gbStd] = base.ImuGyroBias(gyroData);
[ab, abStd] = base.ImuAccBias(accData);

% 4. 打印结果
fprintf('---- 静止零偏估计结果 ----\n');
fprintf('陀螺仪零偏 (X,Y,Z): [%.6f, %.6f, %.6f]\n', gb);
fprintf('加速度零偏 (X,Y,Z): [%.6f, %.6f, %.6f]\n', ab);