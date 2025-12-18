function [bias, stdDev] = ImuAccBias(accData)
% IMUACCBIAS - 估计加速度计在静止状态下的零偏
%
% 输入:
%   accData - Nx3 矩阵，每一列对应 [ax, ay, az]
%
% 输出:
%   bias    - 1x3 加速度计零偏 [bax, bay, baz]
%   stdDev  - 1x3 数据的标准差

    g_norm = 9.80665; % 标准重力加速度 (m/s^2)
    
    % 1. 计算均值
    rawMean = mean(accData, 1);
    stdDev = std(accData, 0, 1);
    
    % 2. 自动识别重力轴
    % 静止时长轴（绝对值最大）通常是重力轴
    [maxVal, maxIdx] = max(abs(rawMean));
    
    % 3. 扣除重力得到零偏
    bias = rawMean;
    % 逻辑：零偏 = 观测均值 - 理论重力分量
    bias(maxIdx) = rawMean(maxIdx) - sign(rawMean(maxIdx)) * g_norm;
    
    % 质量检查
    if abs(maxVal - g_norm) > 0.5
        warning('ImuAccBias: 观测到的重力值(%.2f)偏离标准值较大，请确认单位是否为 m/s^2。', maxVal);
    end
end

