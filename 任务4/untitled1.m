%% 二维桁架有限元程序
% 功能：
% 1. 建立二维桁架有限元模型
% 2. 形成总体刚度矩阵
% 3. 施加位移边界条件
% 4. 求解节点位移
% 5. 计算单元应变、应力、轴力
% 6. 输出支座反力

clear; clc; close all;

%% =========================
% 1. 基本参数输入
% ==========================
E = 30;        % 弹性模量，单位 MPa = N/mm^2
A = 1;         % 横截面积，单位 mm^2
F0 = 3000;     % 节点4水平向右外力，单位 N

%% =========================
% 2. 节点坐标
% 每一行代表一个节点：[x, y]
% ==========================
node = [
    0,   100;     % 节点1：左上支座
    100, 100;     % 节点2：中上支座
    200, 100;     % 节点3：右上支座
    100, 0        % 节点4：下方受力节点
];

nnode = size(node, 1);

%% =========================
% 3. 单元连接关系
% 每一行代表一个单元：[起点节点, 终点节点]
% ==========================
elem = [
    1, 4;
    2, 4;
    3, 4
];

nelem = size(elem, 1);

%% =========================
% 4. 总自由度数
% 每个节点有两个自由度：x方向位移、y方向位移
% 节点i的自由度编号：
% ux = 2*i-1
% uy = 2*i
% ==========================
ndof = 2 * nnode;

K = zeros(ndof, ndof);
F = zeros(ndof, 1);

%% =========================
% 5. 施加载荷
% 节点4水平向右受力F0
% ==========================
F(2*4 - 1) = F0;

%% =========================
% 6. 单元刚度矩阵组装
% ==========================
for e = 1:nelem
    node1 = elem(e, 1);
    node2 = elem(e, 2);

    x1 = node(node1, 1);
    y1 = node(node1, 2);
    x2 = node(node2, 1);
    y2 = node(node2, 2);

    L = sqrt((x2 - x1)^2 + (y2 - y1)^2);

    c = (x2 - x1) / L;
    s = (y2 - y1) / L;

    ke = E * A / L * [
         c^2,  c*s, -c^2, -c*s;
         c*s,  s^2, -c*s, -s^2;
        -c^2, -c*s,  c^2,  c*s;
        -c*s, -s^2,  c*s,  s^2
    ];

    dof = [
        2*node1 - 1, 2*node1, ...
        2*node2 - 1, 2*node2
    ];

    K(dof, dof) = K(dof, dof) + ke;
end

%% =========================
% 7. 施加边界条件
% 节点1、2、3固定
% ==========================
fixedDof = [
    1, 2, ...
    3, 4, ...
    5, 6
];

fixedVal = zeros(length(fixedDof), 1);

allDof = 1:ndof;
freeDof = setdiff(allDof, fixedDof);

Kff = K(freeDof, freeDof);
Kfc = K(freeDof, fixedDof);
Ff = F(freeDof);

uf = Kff \ (Ff - Kfc * fixedVal);

U = zeros(ndof, 1);
U(freeDof) = uf;
U(fixedDof) = fixedVal;

%% =========================
% 8. 计算支座反力
% ==========================
R = K * U - F;

%% =========================
% 9. 计算单元应变、应力、轴力
% ==========================
strain = zeros(nelem, 1);
stress = zeros(nelem, 1);
axialForce = zeros(nelem, 1);

for e = 1:nelem
    node1 = elem(e, 1);
    node2 = elem(e, 2);

    x1 = node(node1, 1);
    y1 = node(node1, 2);
    x2 = node(node2, 1);
    y2 = node(node2, 2);

    L = sqrt((x2 - x1)^2 + (y2 - y1)^2);

    c = (x2 - x1) / L;
    s = (y2 - y1) / L;

    dof = [
        2*node1 - 1, 2*node1, ...
        2*node2 - 1, 2*node2
    ];

    ue = U(dof);

    strain(e) = [-c, -s, c, s] * ue / L;
    stress(e) = E * strain(e);
    axialForce(e) = stress(e) * A;
end

%% =========================
% 10. 输出结果
% ==========================
disp('==============================');
disp('二维桁架有限元计算结果');
disp('==============================');

disp('总体刚度矩阵 K = ');
disp(K);

disp('节点位移结果：');
fprintf('节点号\tUx/mm\t\tUy/mm\n');
for i = 1:nnode
    fprintf('%d\t%.6f\t%.6f\n', i, U(2*i-1), U(2*i));
end

fprintf('\n单元计算结果：\n');
fprintf('单元号\t应变\t\t应力/MPa\t轴力/N\t\t状态\n');

for e = 1:nelem
    if axialForce(e) > 0
        state = '受拉';
    elseif axialForce(e) < 0
        state = '受压';
    else
        state = '零力杆';
    end

    fprintf('%d\t%.6e\t%.6f\t%.6f\t%s\n', ...
        e, strain(e), stress(e), axialForce(e), state);
end

fprintf('\n支座反力：\n');
for i = 1:3
    fprintf('节点%d反力：Rx = %.6f N, Ry = %.6f N\n', ...
        i, R(2*i-1), R(2*i));
end