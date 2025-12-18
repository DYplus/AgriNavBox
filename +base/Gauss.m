function [X, Y, Z] = Gauss(lat, lon, height, varargin)
% GAUSS - 将 WGS84 经纬度（高度）投影至高斯-克吕格平面坐标
%
% 调用格式:
%   [X, Y] = base.Gauss(lat, lon, [])          % 仅经纬度输入
%   [X, Y, Z] = base.Gauss(lat, lon, alt)      % 经纬高输入
%   [...] = base.Gauss(..., 'ZoneWidth', 3)    % 指定3度带 (默认6度)
%   [...] = base.Gauss(..., 'L0', 120.5)       % 强制指定中央子午线

    % 1. 参数解析
    p = inputParser;
    addRequired(p, 'lat');
    addRequired(p, 'lon');
    addOptional(p, 'height', []);
    addParameter(p, 'ZoneWidth', 6); % 默认6度带
    addParameter(p, 'L0', []);       % 自定义中央子午线
    parse(p, lat, lon, height, varargin{:});
    
    zoneWidth = p.Results.ZoneWidth;
    L = lon;
    B = lat;
    H = p.Results.height;

    % 2. WGS84 椭球参数
    a = 6378137.0;              % 长半轴
    f = 1/298.257223563;        % 扁率
    b = a * (1 - f);            % 短半轴
    e2 = (a^2 - b^2) / a^2;     % 第一偏心率平方
    ep2 = (a^2 - b^2) / b^2;    % 第二偏心率平方

    % 3. 确定中央子午线 L0
    if isempty(p.Results.L0)
        if zoneWidth == 6
            zoneNum = floor(L / 6) + 1;
            L0 = zoneNum * 6 - 3;
        else % 3度带
            zoneNum = round(L / 3);
            L0 = zoneNum * 3;
        end
    else
        L0 = p.Results.L0;
    end

    % 4. 投影计算
    radLat = deg2rad(B);
    radLon = deg2rad(L);
    radL0 = deg2rad(L0);
    dL = radLon - radL0;

    cosB = cos(radLat);
    sinB = sin(radLat);
    t = tan(radLat);
    eta2 = ep2 * cosB.^2;
    N = a ./ sqrt(1 - e2 * sinB.^2); % 卯酉圈曲率半径

    % 计算子午弧长 X_arc
    A1 = 1 + 3/4*e2 + 45/64*e2^2 + 175/256*e2^3;
    B1 = 3/4*e2 + 15/16*e2^2 + 525/512*e2^3;
    C1 = 15/64*e2^2 + 105/256*e2^3;
    D1 = 35/512*e2^3;
    
    X_arc = a * (1-e2) * (A1*radLat - B1/2*sin(2*radLat) + C1/4*sin(4*radLat) - D1/6*sin(6*radLat));

    % 平面坐标计算
    X = X_arc + N.*t.*cosB.^2.*dL.^2/2 + ...
        N.*t.*cosB.^4.*(5 - t.^2 + 9*eta2 + 4*eta2.^2).*dL.^4/24 + ...
        N.*t.*cosB.^6.*(61 - 58*t.^2 + t.^4).*dL.^6/720;

    Y = N.*cosB.*dL + ...
        N.*cosB.^3.*(1 - t.^2 + eta2).*dL.^3/6 + ...
        N.*cosB.^5.*(5 - 18*t.^2 + t.^4 + 14*eta2 - 58*t.^2.*eta2).*dL.^5/120;

    % 5. 坐标加偏 (通常东向加 500000 避免负数)
    Y = Y + 500000;
    
    % 6. 处理高度
    if isempty(H)
        Z = zeros(size(X));
    else
        Z = H;
    end
end
