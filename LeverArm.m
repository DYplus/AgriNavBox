%% AgriNavBox - 安装参数估计 (LeverArm)
% 任务：通过非线性最小二乘法估计天线相对于旋转中心（接地点）的杆臂向量 L_GA
% 坐标系：ENU (东-北-天) -> X:右(东), Y:前(北), Z:上(天)
clear; clc;

%% 1. 数据加载与预处理 (调用 +io)
dataDir = 'Data';
fileName = '原地旋转.xlsx';
fullPath = fullfile(dataDir, fileName);

% 提取原始数据
data = readmatrix(fullPath);
posRaw = data(:, 1:3);      % [Lat(deg), Lon(deg), Alt(m)]
imuRaw = data(:, 13:18);    % [acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z]
yawRaw = data(:, 19);       % 双天线或单天线航向 (deg)

%% 2. 坐标与姿态预处理 (调用 +base)
% 2.1 坐标转换: WGS84 -> ENU (站心坐标系)
% P_GA 为 Nx3 [E, N, U] 或 Nx2 [E, N]
[E, N, U] = base.Gauss(posRaw(:,1), posRaw(:,2), posRaw(:,3));
if isempty(U)
    P_GA = [E, N]; 
else
    P_GA = [E, N, U];
end

% 2.2 角度转换: 度(deg) -> 弧度(rad)
% 导航计算统一使用弧度
yawRad = yawRaw * (pi/180);

% 2.3 姿态合成: 合成 Body -> ENU 的旋转矩阵序列 R_D
% 调用我们定义的 antImu2Rotm 函数
fprintf('正在合成三维姿态矩阵 (ENU)... \n');
R_D = base.antImu2Rotm(imuRaw, yawRad); 

%% 3. 非线性优化求解 (调用 +calib)
% 3.1 设定杆臂初始值 L0 (单位: 米)
% L0 = [右偏(x), 前偏(y), 高度(z)]
% 示例: 天线在旋转中心后方1.5m -> y=-1.5; 左侧0.5m -> x=-0.5; 高2.5m -> z=2.5
L0 = [-0.5, -1.5, 2.5]; 

% 3.2 配置优化参数
options = optimoptions('lsqnonlin', ...
    'Algorithm', 'levenberg-marquardt', ...
    'Display', 'iter-detailed', ...
    'FunctionTolerance', 1e-8, ...
    'StepTolerance', 1e-8);

% 3.3 执行非线性估计
% fitArm 内部调用 getErr，且支持 P_GA 维度自动检查
fprintf('开始非线性优化估计杆臂值...\n');
[L_opt, resnorm] = calib.fitArm(P_GA, R_D, L0, options);

%% 4. 结果输出与验证
fprintf('\n==================================================\n');
fprintf('标定成功！最优杆臂向量 (L_GA) 在 ENU 载体坐标系下：\n');
fprintf('X (右向偏移): %.4f 米\n', L_opt(1));
fprintf('Y (前向偏移): %.4f 米\n', L_opt(2));
fprintf('Z (高度偏移): %.4f 米\n', L_opt(3));
fprintf('==================================================\n');

% 验证：计算所有时刻的接地点投影点 P_Gp
N_pts = size(P_GA, 1);
P_Gp = zeros(N_pts, 3);
for k = 1:N_pts
    % 维度对齐处理
    if size(P_GA, 2) == 2
        p_now = [P_GA(k, 1:2), L_opt(3)]'; % 使用拟合的高度补齐
    else
        p_now = P_GA(k, :)';
    end
    % 公式: P_接地点 = P_天线 - R_D * L_杆臂
    P_Gp(k,:) = (p_now - R_D(:,:,k) * L_opt')';
end

%% 5. 可视化分析
figure('Color', 'w', 'Name', '挖掘机安装参数标定验证');

% 子图1：原始天线轨迹
subplot(1,2,1); 
if size(P_GA, 2) == 3
    plot3(P_GA(:,1), P_GA(:,2), P_GA(:,3), 'b.', 'MarkerSize', 8);
else
    plot(P_GA(:,1), P_GA(:,2), 'b.', 'MarkerSize', 8);
end
axis equal; grid on; hold on;
title('原始天线旋转轨迹 (P_{GA})');
xlabel('东向 (E)'); ylabel('北向 (N)');

% 子图2：投影后的接地点分布
subplot(1,2,2); 
plot3(P_Gp(:,1), P_Gp(:,2), P_Gp(:,3), 'r.', 'MarkerSize', 8);
axis equal; grid on;
title('投影至旋转中心点集 (P_{Gp})');
xlabel('东向 (E)'); ylabel('北向 (N)'); zlabel('高度 (U)');

% 计算标准差评估聚合度
std_xyz = std(P_Gp);
fprintf('投影点聚合标准差: E:%.4f, N:%.4f, U:%.4f (米)\n', std_xyz);

