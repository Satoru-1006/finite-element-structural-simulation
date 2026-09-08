%% 一维拉伸杆有限元程序
clear; clc;

fprintf('一维拉伸杆有限元程序\n');
fprintf('请统一单位，例如 N-mm 或 N-m\n\n');

x = input('请输入节点坐标列向量，例如 [0;200;400;600] = ');

elem = input('请输入单元连接矩阵，例如 [1 2;2 3;3 4] = ');

nnode = length(x);
nelem = size(elem, 1);

E = input('请输入弹性模量 E，例如 200000 或 200000*ones(nelem,1) = ');

A = input('请输入截面面积 A，例如 200 或 200*ones(nelem,1) = ');

F = input('请输入节点载荷列向量，例如 [0;0;0;20000] = ');

fixedDof = input('请输入约束节点编号，例如 1 或 [1 3] = ');

fixedVal = input('请输入对应约束位移，例如 0 或 [0;0] = ');

if isscalar(E)
    E = E * ones(nelem, 1);
end

if isscalar(A)
    A = A * ones(nelem, 1);
end

if length(E) ~= nelem
    error('E 的个数必须等于单元数');
end

if length(A) ~= nelem
    error('A 的个数必须等于单元数');
end

if length(F) ~= nnode
    error('载荷向量 F 的长度必须等于节点数');
end

if length(fixedDof) ~= length(fixedVal)
    error('约束节点编号 fixedDof 和约束位移 fixedVal 的数量必须一致');
end

K = zeros(nnode, nnode);

for e = 1:nelem

    node1 = elem(e,1);
    node2 = elem(e,2);

    x1 = x(node1);
    x2 = x(node2);

    Le = x2 - x1;

    if Le <= 0
        error('单元 %d 的长度小于或等于 0，请检查节点坐标或单元连接关系', e);
    end

    ke = E(e) * A(e) / Le * [1 -1; -1 1];

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
    
    stress(e) = E(e) * strain(e);
    
    force(e) = stress(e) * A(e);
end

nodeID = (1:nnode)';
nodeResult = table(nodeID, x, u, ...
    'VariableNames', {'节点编号', '坐标', '位移'});

elemID = (1:nelem)';
node1 = elem(:,1);
node2 = elem(:,2);

elemResult = table(elemID, node1, node2, Le_all, strain, stress, force, ...
    'VariableNames', {'单元编号', '左节点', '右节点', '长度', '应变', '应力', '内力'});

disp('总体刚度矩阵 K = ');
disp(K);

disp('节点位移结果 = ');
disp(nodeResult);

disp('支座反力 R = ');
disp(R);

disp('单元结果 = ');
disp(elemResult);