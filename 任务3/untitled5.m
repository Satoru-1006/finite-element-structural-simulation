%% 一维拉伸杆有限元程序
% 功能：
% 1. 输入节点、单元、材料、载荷、边界条件
% 2. 自动形成并组装总体刚度矩阵
% 3. 施加边界条件
% 4. 求解节点位移
% 5. 计算单元应变、应力、内力
% 6. 输出节点结果和单元结果表

clear; clc;

fprintf('一维拉伸杆有限元程序\n');
fprintf('请统一单位，例如 N-mm 或 N-m\n\n');

%% =========================
% 1. 输入数据
% ==========================

% 节点坐标
x = input('请输入节点坐标列向量，例如 [0;200;400;600] = ');

% 单元连接关系
elem = input('请输入单元连接矩阵，例如 [1 2;2 3;3 4] = ');

% 节点数与单元数
nnode = length(x);
nelem = size(elem, 1);

% 材料参数
E = input('请输入弹性模量 E，例如 200000 或 200000*ones(nelem,1) = ');

% 截面面积
A = input('请输入截面面积 A，例如 200 或 200*ones(nelem,1) = ');

% 节点载荷
F = input('请输入节点载荷列向量，例如 [0;0;0;20000] = ');

% 位移边界条件
fixedDof = input('请输入约束节点编号，例如 1 或 [1 3] = ');
fixedVal = input('请输入对应约束位移，例如 0 或 [0;0] = ');

%% =========================
% 2. 输入数据检查与处理
% ==========================

% 如果 E 是单个数，则扩展为每个单元一个 E
if isscalar(E)
    E = E * ones(nelem, 1);
end

% 如果 A 是单个数，则扩展为每个单元一个 A
if isscalar(A)
    A = A * ones(nelem, 1);
end

% 检查材料参数数量
if length(E) ~= nelem
    error('E 的个数必须等于单元数');
end

% 检查截面面积数量
if length(A) ~= nelem
    error('A 的个数必须等于单元数');
end

% 检查载荷向量长度
if length(F) ~= nnode
    error('载荷向量 F 的长度必须等于节点数');
end

% 检查约束数量
if length(fixedDof) ~= length(fixedVal)
    error('约束节点编号 fixedDof 和约束位移 fixedVal 的数量必须一致');
end

%% =========================
% 3. 初始化总体刚度矩阵
% ==========================

K = zeros(nnode, nnode);

%% =========================
% 4. 单元循环：形成并组装单元刚度矩阵
% ==========================

for e = 1:nelem
    
    % 读取单元左右节点编号
    node1 = elem(e,1);
    node2 = elem(e,2);
    
    % 读取节点坐标
    x1 = x(node1);
    x2 = x(node2);
    
    % 计算单元长度
    Le = x2 - x1;
    
    % 检查单元长度
    if Le <= 0
        error('单元 %d 的长度小于或等于 0，请检查节点坐标或单元连接关系', e);
    end
    
    % 形成单元刚度矩阵
    ke = E(e) * A(e) / Le * [1 -1; -1 1];
    
    % 当前单元对应的总体自由度编号
    dof = [node1 node2];
    
    % 组装到总体刚度矩阵
    for i = 1:2
        for j = 1:2
            K(dof(i), dof(j)) = K(dof(i), dof(j)) + ke(i,j);
        end
    end
end

%% =========================
% 5. 施加边界条件并求解
% ==========================

allDof = 1:nnode;

% 自由自由度
freeDof = setdiff(allDof, fixedDof);

% 提取自由自由度对应的刚度矩阵和载荷向量
Kff = K(freeDof, freeDof);
Kfc = K(freeDof, fixedDof);
Ff = F(freeDof);

% 约束位移列向量
uc = fixedVal(:);

% 求解自由节点位移
uf = Kff \ (Ff - Kfc * uc);

% 组合完整节点位移向量
u = zeros(nnode, 1);
u(freeDof) = uf;
u(fixedDof) = uc;

%% =========================
% 6. 计算支座反力
% ==========================

R = K * u - F;

%% =========================
% 7. 后处理：计算单元应变、应力、内力
% ==========================

strain = zeros(nelem,1);
stress = zeros(nelem,1);
force  = zeros(nelem,1);
Le_all = zeros(nelem,1);

for e = 1:nelem
    
    % 读取单元节点
    node1 = elem(e,1);
    node2 = elem(e,2);
    
    % 读取节点坐标
    x1 = x(node1);
    x2 = x(node2);
    
    % 计算单元长度
    Le = x2 - x1;
    Le_all(e) = Le;
    
    % 单元节点位移向量
    ue = [u(node1); u(node2)];
    
    % 单元应变
    strain(e) = [-1/Le 1/Le] * ue;
    
    % 单元应力
    stress(e) = E(e) * strain(e);
    
    % 单元内力
    force(e) = stress(e) * A(e);
end

%% =========================
% 8. 输出结果
% ==========================

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