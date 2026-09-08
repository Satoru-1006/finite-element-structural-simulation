%% ============================================================
% 任务9：矩形方板拉伸问题 FEM 计算
% 三节点三角形常应变单元 CST
% 子任务 6、7、8、9 一体化代码
% 优化版：修正载荷 + 平滑云图 + 理论对比
%% ============================================================

clc; clear; close all;

%% 1. 基本参数
L  = 1.0;          % 板长 m
H  = 0.4;          % 板高 m
t  = 0.01;         % 厚度 m
E  = 210e9;        % 弹性模量 Pa
nu = 0.30;         % 泊松比
q  = 100e6;        % 右端均布拉应力 Pa

% 平面应力本构矩阵
D = E/(1-nu^2) * [1,  nu, 0;
                  nu, 1,  0;
                  0,  0,  (1-nu)/2];

%% 2. 生成规则三角形网格
nx = 24;           % x方向划分数，可适当加密
ny = 10;           % y方向划分数

xv = linspace(0, L, nx+1);
yv = linspace(-H/2, H/2, ny+1);

nodes = zeros((nx+1)*(ny+1), 2);
id = 1;
for j = 1:ny+1
    for i = 1:nx+1
        nodes(id,:) = [xv(i), yv(j)];
        id = id + 1;
    end
end

nnodes = size(nodes,1);

% 每个矩形剖分为两个三角形
elements = [];
for j = 1:ny
    for i = 1:nx
        n1 = i     + (nx+1)*(j-1);   % 左下
        n2 = n1+1;                   % 右下
        n3 = n1+(nx+1);              % 左上
        n4 = n3+1;                   % 右上

        % 两个三角形，节点按逆时针排列
        elements = [elements;
                    n1, n2, n4;
                    n1, n4, n3];
    end
end

nelem = size(elements,1);

%% 3. 总体刚度矩阵组装
ndof = 2 * nnodes;
K = sparse(ndof, ndof);
F = zeros(ndof, 1);

elem_B = cell(nelem,1);
elem_A = zeros(nelem,1);

for e = 1:nelem
    enodes = elements(e,:);
    xe = nodes(enodes,1);
    ye = nodes(enodes,2);

    x1 = xe(1); x2 = xe(2); x3 = xe(3);
    y1 = ye(1); y2 = ye(2); y3 = ye(3);

    % 三角形面积
    A = 0.5 * det([1 x1 y1;
                   1 x2 y2;
                   1 x3 y3]);

    if A <= 0
        error('第 %d 个单元面积为负或为零，请检查节点顺序。', e);
    end

    % 常应变三角形单元 B 矩阵
    B = 1/(2*A) * [y2-y3, 0,     y3-y1, 0,     y1-y2, 0;
                   0,     x3-x2, 0,     x1-x3, 0,     x2-x1;
                   x3-x2, y2-y3, x1-x3, y3-y1, x2-x1, y1-y2];

    Ke = t * A * (B' * D * B);

    dof = [2*enodes(1)-1, 2*enodes(1), ...
           2*enodes(2)-1, 2*enodes(2), ...
           2*enodes(3)-1, 2*enodes(3)];

    K(dof,dof) = K(dof,dof) + Ke;

    elem_B{e} = B;
    elem_A(e) = A;
end

%% 4. 右边界均布拉力转化为等效节点力
% 这里采用边界线积分思想：
% 每一段右边界边长为 Le，两端节点各分 q*t*Le/2
right_nodes = find(abs(nodes(:,1)-L) < 1e-12);
[~, order] = sort(nodes(right_nodes,2));
right_nodes = right_nodes(order);

for k = 1:length(right_nodes)-1
    nA = right_nodes(k);
    nB = right_nodes(k+1);

    yA = nodes(nA,2);
    yB = nodes(nB,2);
    Le = abs(yB - yA);

    f_edge = q * t * Le / 2;

    F(2*nA-1) = F(2*nA-1) + f_edge;
    F(2*nB-1) = F(2*nB-1) + f_edge;
end

%% 5. 左边界固定边界条件
left_nodes = find(abs(nodes(:,1)) < 1e-12);

fixed_dof = [];
for k = 1:length(left_nodes)
    fixed_dof = [fixed_dof, 2*left_nodes(k)-1, 2*left_nodes(k)];
end

all_dof = 1:ndof;
free_dof = setdiff(all_dof, fixed_dof);

%% 6. 求解总体方程 Kd = F
d = zeros(ndof,1);
d(free_dof) = K(free_dof, free_dof) \ F(free_dof);

Ux = d(1:2:end);
Uy = d(2:2:end);

%% 7. 单元应变与应力计算
elem_strain = zeros(nelem,3);   % [eps_x, eps_y, gamma_xy]
elem_stress = zeros(nelem,3);   % [sigma_x, sigma_y, tau_xy]

for e = 1:nelem
    enodes = elements(e,:);
    dof = [2*enodes(1)-1, 2*enodes(1), ...
           2*enodes(2)-1, 2*enodes(2), ...
           2*enodes(3)-1, 2*enodes(3)];

    de = d(dof);
    strain = elem_B{e} * de;
    stress = D * strain;

    elem_strain(e,:) = strain';
    elem_stress(e,:) = stress';
end

%% 8. 单元结果平均到节点，用于平滑云图显示
node_S11 = elemToNodeAverage(elements, elem_stress(:,1), nnodes);
node_S22 = elemToNodeAverage(elements, elem_stress(:,2), nnodes);
node_S12 = elemToNodeAverage(elements, elem_stress(:,3), nnodes);

node_EX  = elemToNodeAverage(elements, elem_strain(:,1), nnodes);
node_EY  = elemToNodeAverage(elements, elem_strain(:,2), nnodes);
node_GXY = elemToNodeAverage(elements, elem_strain(:,3), nnodes);

%% 9. 理论解对比
sigma_x_theory = q;
sigma_y_theory = 0;
tau_xy_theory  = 0;
u_right_theory = q * L / E;

u_right_FE = mean(Ux(right_nodes));

% 取板中部区域，避免固定端扰动影响
mid_elems = false(nelem,1);
elem_center = zeros(nelem,2);
for e = 1:nelem
    enodes = elements(e,:);
    elem_center(e,:) = mean(nodes(enodes,:),1);
end

mid_elems = elem_center(:,1) > 0.4*L & elem_center(:,1) < 0.8*L;

sigma_x_FE_mid = mean(elem_stress(mid_elems,1));
sigma_y_FE_mid = mean(elem_stress(mid_elems,2));
tau_xy_FE_mid  = mean(elem_stress(mid_elems,3));

u_error = abs(u_right_FE - u_right_theory) / abs(u_right_theory) * 100;
sx_error = abs(sigma_x_FE_mid - sigma_x_theory) / abs(sigma_x_theory) * 100;

fprintf('\n================ 结果对比 ================\n');
fprintf('右端平均位移 Ux_FE       = %.6e m\n', u_right_FE);
fprintf('右端理论位移 Ux_theory   = %.6e m\n', u_right_theory);
fprintf('右端位移误差             = %.3f %%\n\n', u_error);

fprintf('板中部平均 sigma_x_FE    = %.3f MPa\n', sigma_x_FE_mid/1e6);
fprintf('理论 sigma_x             = %.3f MPa\n', sigma_x_theory/1e6);
fprintf('sigma_x 误差             = %.3f %%\n\n', sx_error);

fprintf('板中部平均 sigma_y_FE    = %.3f MPa\n', sigma_y_FE_mid/1e6);
fprintf('理论 sigma_y             = %.3f MPa\n\n', sigma_y_theory/1e6);

fprintf('板中部平均 tau_xy_FE     = %.3f MPa\n', tau_xy_FE_mid/1e6);
fprintf('理论 tau_xy              = %.3f MPa\n', tau_xy_theory/1e6);
fprintf('==========================================\n');

%% 10. 绘图：网格划分图
figure('Name','三角形网格划分图');
triplot(elements, nodes(:,1), nodes(:,2), 'k');
axis equal tight;
xlabel('x / m');
ylabel('y / m');
title('矩形方板三角形常应变单元剖分图');
grid on;

%% 11. 绘图：变形图
scale = 300;  % 位移放大系数，可调整
deformed_nodes = nodes + scale * [Ux, Uy];

figure('Name','变形前后对比图');
triplot(elements, nodes(:,1), nodes(:,2), 'k'); hold on;
triplot(elements, deformed_nodes(:,1), deformed_nodes(:,2), 'r');
axis equal tight;
xlabel('x / m');
ylabel('y / m');
title(['矩形方板变形前后对比，放大系数 = ', num2str(scale)]);
legend('变形前','变形后');
grid on;

%% 12. 绘图：位移云图
plotNodeField(elements, nodes, Ux, 'x方向位移场 U_x', 'U_x / m');
plotNodeField(elements, nodes, Uy, 'y方向位移场 U_y', 'U_y / m');

%% 13. 绘图：平滑应力云图，适合报告展示
plotNodeField(elements, nodes, node_S11/1e6, '\sigma_x 平滑应力云图', '\sigma_x / MPa');
plotNodeField(elements, nodes, node_S22/1e6, '\sigma_y 平滑应力云图', '\sigma_y / MPa');
plotNodeField(elements, nodes, node_S12/1e6, '\tau_{xy} 平滑剪应力云图', '\tau_{xy} / MPa');

%% 14. 绘图：原始单元常值应力图，用于说明 CST 特点
figure('Name','sigma_x 单元常值图');
patch('Faces',elements, ...
      'Vertices',nodes, ...
      'FaceVertexCData',elem_stress(:,1)/1e6, ...
      'FaceColor','flat', ...
      'EdgeColor',[0.75 0.75 0.75]);
axis equal tight;
xlabel('x / m');
ylabel('y / m');
title('\sigma_x 单元常值应力图（CST原始结果）');
cb = colorbar;
ylabel(cb, '\sigma_x / MPa');

%% 15. 沿中线 y=0 的 sigma_x 变化曲线
% 取靠近中线的单元中心
[~, idx_sort] = sort(elem_center(:,1));
center_y = elem_center(:,2);
near_midline = abs(center_y) < H/ny;

x_line = elem_center(near_midline,1);
s11_line = elem_stress(near_midline,1)/1e6;

[x_line, idx] = sort(x_line);
s11_line = s11_line(idx);

figure('Name','沿中线 sigma_x 变化曲线');
plot(x_line, s11_line, 'o-', 'LineWidth', 1.2); hold on;
yline(q/1e6, '--', '理论值 q = 100 MPa');
grid on;
xlabel('x / m');
ylabel('\sigma_x / MPa');
title('沿中线附近的 \sigma_x 变化曲线');
legend('有限元结果','理论均匀拉伸值');

%% 16. 导出结果表格
node_table = table((1:nnodes)', nodes(:,1), nodes(:,2), Ux, Uy, ...
    'VariableNames', {'Node','x','y','Ux','Uy'});

elem_table = table((1:nelem)', elem_center(:,1), elem_center(:,2), ...
    elem_stress(:,1), elem_stress(:,2), elem_stress(:,3), ...
    elem_strain(:,1), elem_strain(:,2), elem_strain(:,3), ...
    'VariableNames', {'Element','xc','yc','S11','S22','S12','E11','E22','G12'});

writetable(node_table, 'task9_node_displacement.csv');
writetable(elem_table, 'task9_element_stress_strain.csv');

disp('已导出：task9_node_displacement.csv');
disp('已导出：task9_element_stress_strain.csv');

%% ============================================================
% 局部函数：单元结果平均到节点
%% ============================================================
function node_value = elemToNodeAverage(elements, elem_value, nnodes)
    node_value = zeros(nnodes,1);
    count = zeros(nnodes,1);

    nelem = size(elements,1);
    for e = 1:nelem
        for k = 1:3
            n = elements(e,k);
            node_value(n) = node_value(n) + elem_value(e);
            count(n) = count(n) + 1;
        end
    end

    node_value = node_value ./ count;
end

%% ============================================================
% 局部函数：绘制节点场平滑云图
%% ============================================================
function plotNodeField(elements, nodes, field, figTitle, cbLabel)
    figure('Name', figTitle);
    patch('Faces',elements, ...
          'Vertices',nodes, ...
          'FaceVertexCData',field, ...
          'FaceColor','interp', ...
          'EdgeColor','none');

    axis equal tight;
    xlabel('x / m');
    ylabel('y / m');
    title(figTitle);

    cb = colorbar;
    ylabel(cb, cbLabel);
end