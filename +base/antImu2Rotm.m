function R_D = antImu2Rotm(imuData, yawAnt)
% ANTIMU2ROTM - 融合天线航向与IMU水平姿态合成 ENU 旋转矩阵
%
% 逻辑:
%   1. 基于加速度计计算 Roll/Pitch (假设准静态，重力矢量对齐)
%   2. 结合天线提供的 ENU 航向角 Yaw (正北为0, 逆时针为正 或 按照数据源定义)
%   3. 按照 ENU 标准合成 R_D = Rz(yaw) * Ry(pitch) * Rx(roll)
%
% 输入参数:
%   imuData - Nx6 矩阵: [acc_x, acc_y, acc_z, ...] 单位 m/s^2
%   yawAnt  - Nx1 向量: 航向角 (rad)，需符合 ENU 习惯
%
% 输出参数:
%   R_D     - 3x3xN 矩阵: Body -> ENU 的旋转矩阵序列

    N = size(imuData, 1);
    R_D = zeros(3, 3, N);
    acc = imuData(:, 1:3);
    
    % --- 1. 计算水平姿态 (基于重力矢量) ---
    % Roll: 绕X轴旋转
    roll = atan2(acc(:, 2), acc(:, 3)); 
    % Pitch: 绕Y轴旋转
    pitch = atan2(-acc(:, 1), sqrt(acc(:, 2).^2 + acc(:, 3).^2));

    % --- 2. 循环合成 ENU 旋转矩阵 ---
    for k = 1:N
        r = roll(k);
        p = pitch(k);
        y = yawAnt(k);
        
        % Rx: 绕X轴(右向)旋转 - Roll
        Rx = [1, 0, 0; 0, cos(r), -sin(r); 0, sin(r), cos(r)];
        
        % Ry: 绕Y轴(前向)旋转 - Pitch
        Ry = [cos(p), 0, sin(p); 0, 1, 0; -sin(p), 0, cos(p)];
        
        % Rz: 绕Z轴(天向)旋转 - Yaw
        Rz = [cos(y), -sin(y), 0; sin(y), cos(y), 0; 0, 0, 1];
        
        % 合成 Body to ENU 矩阵
        R_D(:, :, k) = Rz * Ry * Rx;
    end
end

