function [L_best, resnorm] = fitArm(P_GA, R_D, L0, options)
% FITARM - 通过非线性优化拟合天线安装杆臂参数
%
% 输入参数:
%    P_GA    - Nx2 或 Nx3 矩阵: GNSS位置序列 [E, N] 或 [E, N, U]
%    R_D     - 3x3xN 数组: 载体到导航系的旋转矩阵
%    L0      - 1x3 向量: 杆臂初值 [dx, dy, dz]
%    options - 优化配置项: 由 optimoptions('lsqnonlin',...) 生成
%
% 输出参数:
%    L_best  - 1x3 向量: 优化后的最优安装杆臂参数
%    resnorm - 标量: 残差平方和

    % 1. 映射目标函数至修改后的 getErr
    % 无论 P_GA 是几列，getErr 内部都会自动处理维度补齐
    fun = @(L) calib.getErr(L, P_GA, R_D);
    
    % 2. 设置参数约束
    % 如果 P_GA 只有2列，算法无法有效观测到高度变化
    % 此时建议锁定 L(3) 的变动范围，或者由用户根据实际情况在外部设置 lb, ub
    lb = []; ub = []; 
    if size(P_GA, 2) == 2
        % 示例：允许平面偏移有较大搜索空间，但限制高度在初值上下 10cm 波动
        lb = [L0(1)-5, L0(2)-5, L0(3)-0.1]; 
        ub = [L0(1)+5, L0(2)+5, L0(3)+0.1];
    end
    
    % 3. 调用非线性最小二乘优化器
    % 格式: lsqnonlin(fun, x0, lb, ub, options)
    [L_best, resnorm] = lsqnonlin(fun, L0, lb, ub, options);
    
end

