%% 一维杆单元有限元程序
% 功能：
% 1. 建立一维杆单元有限元模型
% 2. 形成总体刚度矩阵
% 3. 施加位移边界条件
% 4. 求解节点位移
% 5. 计算单元应变、应力、内力
% 6. 输出支座反力

clear; clc; close all;

%% =========================
% 1. 基本参数输入
% ==========================
Le0 = 30;          % 每个单元长度，单位 mm
A = 1;             % 截面面积，单位 mm^2
E = 30;            % 弹性模量，单位 MPa = N/mm^2
P = 3000;          % 节点2水平向右集中力，单位 N

nelem = 3;         % 单元数
nnode = nelem + 1; % 节点数

%% =========================
% 2. 节点坐标与单元连接关系
% ==========================
x = [0; 30; 60; 90];       % 节点坐标，单位 mm

elem = [1 2;
        2 3;
        3 4];              % 单元连接关系

%% =========================
% 3. 外载荷与边界条件
% ==========================
F = zeros(nnode, 1);       % 总体载荷向量
F(2) = P;                  % 节点2施加3000N水平向右的力

fixedDof = [1 4];          % 节点1和节点4固定
fixedVal = [0; 0];         % 约束位移均为0

%% =========================
% 4. 初始化总体刚度矩阵
% ==========================
K = zeros(nnode, nnode);

%% =========================
% 5. 单元循环：形成并组装单元刚度矩阵
% ==========================
for e = 1:nelem
    node1 = elem(e, 1);
    node2 = elem(e, 2);

    x1 = x(node1);
    x2 = x(node2);
    Le = x2 - x1;

    ke = E * A / Le * [1 -1;
                      -1  1];

    dof = [node1, node2];

    K(dof, dof) = K(dof, dof) + ke;
end

%% =========================
% 6. 施加边界条件并求解节点位移
% ==========================
allDof = 1:nnode;
freeDof = setdiff(allDof, fixedDof);

Kff = K(freeDof, freeDof);
Kfc = K(freeDof, fixedDof);
Ff = F(freeDof);

uc = fixedVal(:);

uf = Kff \ (Ff - Kfc * uc);

U = zeros(nnode, 1);
U(freeDof) = uf;
U(fixedDof) = uc;

%% =========================
% 7. 计算支座反力
% ==========================
R = K * U - F;

%% =========================
% 8. 后处理：计算单元应变、应力、内力
% ==========================
strain = zeros(nelem, 1);
stress = zeros(nelem, 1);
internalForce = zeros(nelem, 1);

for e = 1:nelem
    node1 = elem(e, 1);
    node2 = elem(e, 2);

    x1 = x(node1);
    x2 = x(node2);
    Le = x2 - x1;

    u1 = U(node1);
    u2 = U(node2);

    strain(e) = (u2 - u1) / Le;
    stress(e) = E * strain(e);
    internalForce(e) = stress(e) * A;
end

%% =========================
% 9. 输出结果
% ==========================
disp('==============================');
disp('一维三单元杆有限元计算结果');
disp('==============================');

fprintf('单元长度 Le = %.2f mm\n', Le0);
fprintf('截面面积 A = %.2f mm^2\n', A);
fprintf('弹性模量 E = %.2f MPa\n', E);
fprintf('节点2外载荷 P = %.2f N\n', P);
fprintf('单元数 = %d\n', nelem);
fprintf('节点数 = %d\n\n', nnode);

disp('总体刚度矩阵 K = ');
disp(K);

disp('总体载荷向量 F = ');
disp(F);

disp('节点位移结果：');
fprintf('节点号\t坐标/mm\t\t位移/mm\n');
for i = 1:nnode
    fprintf('%d\t%.2f\t\t%.6f\n', i, x(i), U(i));
end

fprintf('\n单元计算结果：\n');
fprintf('单元号\t长度/mm\t\t应变\t\t应力/MPa\t内力/N\n');
for e = 1:nelem
    node1 = elem(e, 1);
    node2 = elem(e, 2);
    Le = x(node2) - x(node1);

    fprintf('%d\t%.2f\t\t%.6e\t%.3f\t\t%.3f\n', ...
        e, Le, strain(e), stress(e), internalForce(e));
end

fprintf('\n支座反力：\n');
fprintf('节点1支座反力 R1 = %.3f N\n', R(1));
fprintf('节点4支座反力 R4 = %.3f N\n', R(4));

fprintf('\n最大位移 = %.6f mm\n', max(abs(U)));
fprintf('最大应力 = %.3f MPa\n', max(abs(stress)));

%% =========================
% 10. 简单绘制变形图
% ==========================
scale = 0.01;

figure;
plot(x, zeros(size(x)), 'ko-', 'LineWidth', 1.5);
hold on;
plot(x + scale * U, zeros(size(x)), 'ro--', 'LineWidth', 1.5);
grid on;
xlabel('x / mm');
ylabel('杆轴线');
legend('原始位置', '变形后位置');
title('一维杆结构变形图');