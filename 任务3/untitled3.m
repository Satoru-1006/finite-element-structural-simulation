%% 一维拉伸杆有限元程序 
% 功能：
% 1. 输入节点、单元、材料、载荷、边界条件
% 2. 形成总体刚度矩阵
% 3. 施加边界条件
% 4. 求解节点位移
% 5. 计算单元应变、应力、内力

clear; clc;

%% =========================
% 1. 输入数据
% ==========================

x = [0; 1; 2];

elem = [1 2;
        2 3];

E = 210e9;
A = 1.0e-4;

nnode = length(x);
nelem = size(elem, 1);

F = zeros(nnode, 1);
F(3) = 1000;

fixedDof = [1];
fixedVal = [0];

%% =========================
% 2. 初始化总体刚度矩阵
% ==========================

K = zeros(nnode, nnode);

%% =========================
% 3. 单元循环：形成并组装单元刚度矩阵
% ==========================

for e = 1:nelem

    node1 = elem(e,1);
    node2 = elem(e,2);

    x1 = x(node1);
    x2 = x(node2);

    Le = x2 - x1;

    ke = E * A / Le * [1 -1; -1 1];

    dof = [node1 node2];

    for i = 1:2
        for j = 1:2
            K(dof(i), dof(j)) = K(dof(i), dof(j)) + ke(i,j);
        end
    end
end

%% =========================
% 4. 施加边界条件并求解
% ==========================

allDof = 1:nnode;
freeDof = setdiff(allDof, fixedDof);

Kff = K(freeDof, freeDof);
Kfc = K(freeDof, fixedDof);
Ff = F(freeDof);

uc = fixedVal(:);

uf = Kff \ (Ff - Kfc * uc);

u = zeros(nnode, 1);
u(freeDof) = uf;
u(fixedDof) = uc;

%% =========================
% 5. 计算支座反力
% ==========================

R = K * u - F;

%% =========================
% 6. 后处理：计算单元应变、应力、内力
% ==========================

strain = zeros(nelem,1);
stress = zeros(nelem,1);
force  = zeros(nelem,1);

for e = 1:nelem
    
    node1 = elem(e,1);
    node2 = elem(e,2);
    
    x1 = x(node1);
    x2 = x(node2);

    Le = x2 - x1;
    
    ue = [u(node1); u(node2)];
    
    strain(e) = [-1/Le 1/Le] * ue;
    
    stress(e) = E * strain(e);
    
    force(e) = stress(e) * A;
end

%% =========================
% 7. 输出结果
% ==========================

disp('总体刚度矩阵 K = ');
disp(K);

disp('节点位移 u = ');
disp(u);

disp('支座反力 R = ');
disp(R);

disp('单元应变 strain = ');
disp(strain);

disp('单元应力 stress = ');
disp(stress);

disp('单元内力 force = ');
disp(force);