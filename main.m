%% AgriNavBox 极速处理流程
clear; clc; tic;

% 1. 调用解析函数
% 确保 Data/14_054539.txt 路径正确
g_data = io.getLogFromBin('Data/9.txt', 'false');

data = g_data(10000:15000, :);

% 2. 验证解析是否成功
if isempty(data) || height(data) == 0
    error('解析结果为空，请检查 getLogFromBin 中的年份过滤逻辑或同步头偏移。');
else
    fprintf('解析成功，共获取 %d 帧轨迹点。\n', height(data));
end

% 3. 绘制图形
figure('Color', 'w'); % 强制打开一个新窗口
plot(data.lon, data.lat, 'LineWidth', 1.5);
hold on;
% 标出起点（绿）和终点（红）
plot(data.lon(1), data.lat(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot(data.lon(end), data.lat(end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

grid on;
axis equal; % 保持经纬度比例正常
xlabel('Longitude (deg)');
ylabel('Latitude (deg)');
title('由二进制流解析生成的实时轨迹');
% 2. 截取 10000 到 15000 行
subData = g_data(10000:15000, :);

% 3. 调用高斯投影 (默认3度带)
[gx, gy, gz] = base.Gauss(subData.lat, subData.lon, []);

% 4. 存回表格进行后续处理
subData.gx = gx;
subData.gy = gy;
subData.gz = gz;

% 可视化测试
figure;
plot(subData.gy, subData.gx, 'LineWidth', 1.5);
axis equal; grid on;
xlabel('East (m)'); ylabel('North (m)');
title('高斯投影平面轨迹 (3度带)');

toc;
