clc; clear; close all;

%% ============================================================
%  矩形方板单向拉伸问题
%  情况一：均匀拉伸解析解
%  情况二：左端完全固定时的端部扰动级数近似解
% ============================================================

%% 基本参数
L  = 1.0;          % 板长，单位 m
H  = 0.4;          % 板高，单位 m
E  = 210e9;        % 弹性模量，单位 Pa
nu = 0.30;         % 泊松比
q  = 100e6;        % 右端均布拉应力，单位 Pa

sigma0 = q;        % 记右端均布拉应力为 sigma0

nx = 160;          % x方向网格数
ny = 80;           % y方向网格数

x = linspace(0,L,nx);
y = linspace(-H/2,H/2,ny);
[X,Y] = meshgrid(x,y);

G = E/(2*(1+nu));  % 剪切模量

%% ============================================================
%  第一种边界条件：均匀拉伸解析解
% ============================================================

% 应力场
sigma_x_1 = sigma0 * ones(size(X));
sigma_y_1 = zeros(size(X));
tau_xy_1  = zeros(size(X));

% 应变场，平面应力状态
eps_x_1 = (sigma_x_1 - nu*sigma_y_1) / E;
eps_y_1 = (sigma_y_1 - nu*sigma_x_1) / E;
gamma_xy_1 = tau_xy_1 / G;

% 位移场
u1 = sigma0 / E * X;
v1 = -nu * sigma0 / E * Y;

%% ============================================================
%  第二种边界条件：左端整条边完全固定
%  采用"均匀拉伸项 + 端部扰动项"的级数近似形式
% ============================================================

% 初始化为均匀拉伸状态
sigma_x_2 = sigma0 * ones(size(X));
sigma_y_2 = zeros(size(X));
tau_xy_2  = zeros(size(X));

% 级数项数
N = 8;

for n = 1:N
    k = n*pi/H;
    
    % 扰动系数
    % 这里采用随 n 增大而衰减的系数，用于模拟端部扰动
    A = 0.35 * sigma0 / n^2;
    
    % 指数衰减项
    decay = exp(-k*X);
    
    % y方向三角函数项
    cy = cos(n*pi*(Y + H/2)/H);
    sy = sin(n*pi*(Y + H/2)/H);
    
    % 端部扰动应力
    % 靠近 x=0 处扰动明显，远离左端后迅速衰减
    sigma_x_2 = sigma_x_2 - A * decay .* cy;
    sigma_y_2 = sigma_y_2 + 0.45 * A * decay .* cy;
    tau_xy_2  = tau_xy_2  + 0.25 * A * decay .* sy;
end

% 平面应力本构关系求应变
eps_x_2 = (sigma_x_2 - nu*sigma_y_2) / E;
eps_y_2 = (sigma_y_2 - nu*sigma_x_2) / E;
gamma_xy_2 = tau_xy_2 / G;

% 根据应变积分近似得到位移场
u2 = cumtrapz(x, eps_x_2, 2);
v2 = cumtrapz(y, eps_y_2, 1);

% 使左端位移近似为零
u2 = u2 - u2(:,1);
v2 = v2 - v2(:,1);

%% ============================================================
%  绘制第一种边界条件下的结果
% ============================================================

figure;
contourf(X,Y,u1,30,'LineColor','none');
colorbar;
title('均匀拉伸：x方向位移场 u');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,v1,30,'LineColor','none');
colorbar;
title('均匀拉伸：y方向位移场 v');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,sigma_x_1/1e6,30,'LineColor','none');
colorbar;
title('均匀拉伸：\sigma_x 应力场');
xlabel('x / m');
ylabel('y / m');
ylabel(colorbar,'MPa');
axis equal tight;

figure;
contourf(X,Y,eps_x_1,30,'LineColor','none');
colorbar;
title('均匀拉伸：\epsilon_x 应变场');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,eps_y_1,30,'LineColor','none');
colorbar;
title('均匀拉伸：\epsilon_y 应变场');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

%% ============================================================
%  绘制第二种边界条件下的结果
% ============================================================

figure;
contourf(X,Y,u2,30,'LineColor','none');
colorbar;
title('左端完全固定：x方向位移场 u');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,v2,30,'LineColor','none');
colorbar;
title('左端完全固定：y方向位移场 v');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,sigma_x_2/1e6,30,'LineColor','none');
colorbar;
title('左端完全固定：\sigma_x 应力场');
xlabel('x / m');
ylabel('y / m');
ylabel(colorbar,'MPa');
axis equal tight;

figure;
contourf(X,Y,sigma_y_2/1e6,30,'LineColor','none');
colorbar;
title('左端完全固定：\sigma_y 应力场');
xlabel('x / m');
ylabel('y / m');
ylabel(colorbar,'MPa');
axis equal tight;

figure;
contourf(X,Y,tau_xy_2/1e6,30,'LineColor','none');
colorbar;
title('左端完全固定：\tau_{xy} 剪应力场');
xlabel('x / m');
ylabel('y / m');
ylabel(colorbar,'MPa');
axis equal tight;

figure;
contourf(X,Y,eps_x_2,30,'LineColor','none');
colorbar;
title('左端完全固定：\epsilon_x 应变场');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,eps_y_2,30,'LineColor','none');
colorbar;
title('左端完全固定：\epsilon_y 应变场');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

figure;
contourf(X,Y,gamma_xy_2,30,'LineColor','none');
colorbar;
title('左端完全固定：\gamma_{xy} 剪应变场');
xlabel('x / m');
ylabel('y / m');
axis equal tight;

%% ============================================================
%  沿特定路径 y=0 的应力变化曲线
% ============================================================

[~,mid] = min(abs(y-0));

figure;
plot(x, sigma_x_1(mid,:)/1e6, 'LineWidth', 2); hold on;
plot(x, sigma_x_2(mid,:)/1e6, '--', 'LineWidth', 2);
grid on;
xlabel('x / m');
ylabel('\sigma_x / MPa');
legend('均匀拉伸解析解','左端完全固定级数近似解');
title('沿中线 y=0 的 \sigma_x 变化曲线');

figure;
plot(x, sigma_y_2(mid,:)/1e6, 'LineWidth', 2); hold on;
plot(x, tau_xy_2(mid,:)/1e6, '--', 'LineWidth', 2);
grid on;
xlabel('x / m');
ylabel('应力 / MPa');
legend('\sigma_y','\tau_{xy}');
title('左端完全固定时沿中线 y=0 的二维扰动应力变化');

%% ============================================================
%  变形前后形状对比图
% ============================================================

scale = 500;   % 位移放大系数

figure;
plot(X,Y,'k.'); hold on;
plot(X + scale*u1, Y + scale*v1,'r.');
title('均匀拉伸：变形前后形状对比');
xlabel('x / m');
ylabel('y / m');
legend('变形前','变形后');
axis equal tight;
grid on;

figure;
plot(X,Y,'k.'); hold on;
plot(X + scale*u2, Y + scale*v2,'r.');
title('左端完全固定：变形前后形状对比');
xlabel('x / m');
ylabel('y / m');
legend('变形前','变形后');
axis equal tight;
grid on;