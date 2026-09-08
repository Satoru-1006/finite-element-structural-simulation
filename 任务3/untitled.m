%% 一维杆有限元程序验证算例
clear; clc;

format shortG

x = [0; 200; 400; 600];

elem = [1 2;
        2 3;
        3 4];

E = 200000;
A = 200;

nnode = length(x);
nelem = size(elem, 1);

F = zeros(nnode, 1);
F(4) = 20000;

fixedDof = 1;
fixedVal = 0;

K = zeros(nnode, nnode);

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

R = K * u - F;

strain = zeros(nelem,1);
stress = zeros(nelem,1);
force  = zeros(nelem,1);
Le_all = zeros(nelem,1);

for e = 1:nelem

    node1 = elem(e,1);
    node2 = elem(e,2);

    x1 = x(node1);
    x2 = x(node2);

    Le = x2 - x1;
    Le_all(e) = Le;

    ue = [u(node1); u(node2)];

    strain(e) = [-1/Le 1/Le] * ue;

    stress(e) = E * strain(e);

    force(e) = stress(e) * A;
end

nodeID = (1:nnode)';
nodeResult = table(nodeID, x, u, ...
    'VariableNames', {'节点编号', '坐标_mm', '位移_mm'});

elemID = (1:nelem)';
node1 = elem(:,1);
node2 = elem(:,2);

elemResult = table(elemID, node1, node2, Le_all, strain, stress, force, ...
    'VariableNames', {'单元编号', '左节点', '右节点', '长度_mm', '应变', '应力_MPa', '内力_N'});

disp('总体刚度矩阵 K = ');
disp(K);

disp('节点位移结果 = ');
disp(nodeResult);

disp('支座反力 R = ');
disp(R);

disp('单元结果 = ');
disp(elemResult);