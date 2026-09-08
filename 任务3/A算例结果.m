clear; clc;

fprintf('\n================ 算例 1：3 单元杆件 ================\n');

nodeCoord = [0; 200; 400; 600];
elemConn  = [1 2; 2 3; 3 4];

E = 200000 * ones(3,1);
A = 200 * ones(3,1);

F = zeros(4,1);
F(4) = 20000;

fixedDof = 1;
fixedValue = 0;

result1 = oneDBarFEM(nodeCoord, elemConn, E, A, F, fixedDof, fixedValue);

disp('节点位移结果：');
disp(result1.nodeTable);

disp('单元应变、应力结果：');
disp(result1.elemTable);

disp('总体刚度矩阵 K：');
disp(result1.K);

disp('支反力向量 R：');
disp(result1.reaction);


fprintf('\n================ 算例 2：2 单元杆件 ================\n');

nodeCoord = [0; 300; 600];
elemConn  = [1 2; 2 3];

E = 200000 * ones(2,1);
A = 200 * ones(2,1);

F = zeros(3,1);
F(3) = 20000;

fixedDof = 1;
fixedValue = 0;

result2 = oneDBarFEM(nodeCoord, elemConn, E, A, F, fixedDof, fixedValue);

disp('节点位移结果：');
disp(result2.nodeTable);

disp('单元应变、应力结果：');
disp(result2.elemTable);

disp('总体刚度矩阵 K：');
disp(result2.K);

disp('支反力向量 R：');
disp(result2.reaction);


function result = oneDBarFEM(nodeCoord, elemConn, E, A, F, fixedDof, fixedValue)

    numNode = length(nodeCoord);
    numElem = size(elemConn, 1);

    K = zeros(numNode, numNode);
    elemK = cell(numElem, 1);

    for e = 1:numElem

        node_i = elemConn(e, 1);
        node_j = elemConn(e, 2);

        le = nodeCoord(node_j) - nodeCoord(node_i);

        if le <= 0
            error('单元 %d 的长度小于或等于 0，请检查节点坐标或连接关系。', e);
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

    result.K = K;
    result.U = U;
    result.reaction = reaction;
    result.elemK = elemK;
    result.nodeTable = nodeTable;
    result.elemTable = elemTable;
end