function [bias, stdDev] = ImuGyroBias(gyroData)
% IMUGYROBIAS - 估计陀螺仪在静止状态下的零偏
%
% 输入:
%   gyroData - Nx3 矩阵，每一列对应 [gx, gy, gz]
%
% 输出:
%   bias     - 1x3 陀螺仪零偏 [bgx, bgy, bgz]
%   stdDev   - 1x3 数据的标准差，用于判断静止质量

    % 计算均值作为零偏
    bias = mean(gyroData, 1);
    
    % 计算标准差
    stdDev = std(gyroData, 0, 1);
    
    % 质量检查 (示例阈值，可根据传感器手册调整)
    if any(stdDev > 0.02) 
        warning('ImuGyroBias: 数据波动较大，请检查设备是否完全静止。');
    end
end

