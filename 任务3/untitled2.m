clear; clc;

fprintf('一维杆有限元自动求解程序\n');
fprintf('请统一采用 N-mm 单位制\n\n');

nodeCoord = input('请输入节点坐标列向量，例如 [0;200;400;600] = ');

elemConn = input('请输入单元连接矩阵，例如 [1 2;2 3;3 4] = ');

numNode = length(nodeCoord);
numElem = size(elemConn, 1);

E = input('请输入各单元弹性模量列向量，例如 200000*ones(3,1) = ');

A = input('请输入各单元截面面积列向量，例如 200*ones(3,1) = ');

F = input('请输入节点载荷列向量，例如 [0;0;0;20000] = ');

fixedDof = input('请输入约束节点编号，例如 1 或 [1 3] = ');

fixedValue = input('请输入对应约束位移，例如 0 或 [0;0] = ');

if length(E) ~= numElem
    error('E 的个数必须等于单元数');
end

if length(A) ~= numElem
    error('A 的个数必须等于单元数');
end

if length(F) ~= numNode
    error('载荷向量 F 的长度必须等于节点数');
end

if length(fixedDof) ~= length(fixedValue)
    error('约束节点编号 fixedDof 和约束位移 fixedValue 的数量必须一致');
end

K = zeros(numNode, numNode);
elemK = cell(numElem, 1);

for e = 1:numElem

    node_i = elemConn(e, 1);
    node_j = elemConn(e, 2);

    le = nodeCoord(node_j) - nodeCoord(node_i);

    if le <= 0
        error('单元 %d 的长度小于或等于 0，请检查节点坐标或连接关系', e);
    end

    ke = E(e) * A(e) / le * [1 -1; -1 1];

    elemK{e} = ke;

    dof = [node_i, node_j];

    K(dof, dof) = K(dof, dof) + ke;
end

allDof = 1:numNode;
freeDof = setdiff(allDof, fixedDof);

U = zeros(numNode, 1);
U(fixedDof) = fixedValue;

Kff = K(freeDof, freeDof);
Kfc = K(freeDof, fixedDof);

Ff = F(freeDof);

U(freeDof) = Kff \ (Ff - Kfc * U(fixedDof));

reaction = K * U - F;

strain = zeros(numElem, 1);
stress = zeros(numElem, 1);
elemLength = zeros(numElem, 1);
axialForce = zeros(numElem, 1);

for e = 1:numElem

    node_i = elemConn(e, 1);
    node_j = elemConn(e, 2);

    le = nodeCoord(node_j) - nodeCoord(node_i);
    elemLength(e) = le;

    ui = U(node_i);
    uj = U(node_j);

    strain(e) = (uj - ui) / le;
    stress(e) = E(e) * strain(e);
    axialForce(e) = stress(e) * A(e);
end

nodeID = (1:numNode)';
nodeTable = table(nodeID, nodeCoord, U, ...
    'VariableNames', {'节点编号', '坐标_mm', '位移_mm'});

elemID = (1:numElem)';
node_i = elemConn(:,1);
node_j = elemConn(:,2);

elemTable = table(elemID, node_i, node_j, elemLength, E, A, strain, stress, axialForce, ...
    'VariableNames', {'单元编号', '左节点', '右节点', '长度_mm', ...
                      'E_N每mm2', 'A_mm2', '应变', '应力_MPa', '轴力_N'});

fprintf('\n总体刚度矩阵 K：\n');
disp(K);

fprintf('\n节点位移结果：\n');
disp(nodeTable);

fprintf('\n单元应变、应力结果：\n');
disp(elemTable);

fprintf('\n支反力向量 R：\n');
disp(reaction);

fprintf('\n各单元刚度矩阵：\n');
for e = 1:numElem
    fprintf('\n单元 %d 刚度矩阵：\n', e);
    disp(elemK{e});
end