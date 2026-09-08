%% =========================================================
%  二维三角形平面桁架有限元分析 + Abaqus 建模/分析/后处理
%  任务：计算节点位移、支座反力、杆件轴力，并用 Abaqus 复核
%
%  单位：
%  长度：mm
%  力：N
%  应力：N/mm^2 = MPa
% =========================================================

clear; clc; close all;

%% 1. 材料与截面参数
E = 200000;         % 弹性模量，N/mm^2
A = 300;            % 截面面积，mm^2
P = 10000;          % 节点3竖向向下集中力，N

% 是否自动调用 Abaqus。
% 如果电脑已配置 abaqus 命令，设为 true；否则脚本仍会生成 Abaqus Python 文件。
runAbaqus = true;

%% 2. 节点坐标表
% 每行格式：[x  y]
node = [...
    0    , 0   ;   % 节点1
    1000 , 0   ;   % 节点2
    500  , 800 ];  % 节点3

%% 3. 单元连接表
% 每行格式：[起点节点号  终点节点号]
elem = [...
    1  2 ;
    1  3 ;
    2  3 ];

nNode = size(node,1);
nElem = size(elem,1);
ndof  = 2 * nNode;          % 每个节点 ux、uy 两个自由度

%% 4. 绘制结构图
figure('Name','二维三角形桁架');
hold on; axis equal; grid on;
title('二维三角形桁架结构图');
xlabel('x / mm'); ylabel('y / mm');

for e = 1:nElem
    n1 = elem(e,1);
    n2 = elem(e,2);
    plot(node([n1,n2],1), node([n1,n2],2), 'b-', 'LineWidth', 2);
end

plot(node(:,1), node(:,2), 'ro', 'MarkerFaceColor', 'r');
for i = 1:nNode
    text(node(i,1)+20, node(i,2)+20, ['节点', num2str(i)]);
end

%% 5. 初始化总体刚度矩阵
K = zeros(ndof, ndof);

L_elem = zeros(nElem,1);
c_elem = zeros(nElem,1);
s_elem = zeros(nElem,1);

%% 6. 逐单元计算并组装总体刚度矩阵
for e = 1:nElem
    n1 = elem(e,1);
    n2 = elem(e,2);

    x1 = node(n1,1);  y1 = node(n1,2);
    x2 = node(n2,1);  y2 = node(n2,2);

    Le = sqrt((x2-x1)^2 + (y2-y1)^2);
    c  = (x2-x1) / Le;
    s  = (y2-y1) / Le;

    L_elem(e) = Le;
    c_elem(e) = c;
    s_elem(e) = s;

    ke = E * A / Le * ...
        [ c^2,   c*s,  -c^2,  -c*s;
          c*s,   s^2,  -c*s,  -s^2;
         -c^2,  -c*s,   c^2,   c*s;
         -c*s,  -s^2,   c*s,   s^2 ];

    dof = [2*n1-1, 2*n1, 2*n2-1, 2*n2];
    K(dof, dof) = K(dof, dof) + ke;
end

%% 7. 输出单元几何信息
disp('================ 单元几何信息 ================');
for e = 1:nElem
    fprintf('单元 %d: L = %.3f mm, c = %.4f, s = %.4f\n', ...
        e, L_elem(e), c_elem(e), s_elem(e));
end

%% 8. 建立载荷向量
F = zeros(ndof,1);
F(6) = -P;          % 节点3的 uy 自由度

%% 9. 施加边界条件
% 节点1固定：ux1 = 0, uy1 = 0
% 节点2滚动支座：uy2 = 0
fixed_dof = [1 2 4];

all_dof  = 1:ndof;
free_dof = setdiff(all_dof, fixed_dof);

%% 10. 求解节点位移
U = zeros(ndof,1);

Kff = K(free_dof, free_dof);
Ff  = F(free_dof);

U(free_dof) = Kff \ Ff;

%% 11. 计算支座反力
R = K * U - F;

%% 12. 输出节点位移
disp('================ MATLAB 节点位移结果 ================');
for i = 1:nNode
    ux = U(2*i-1);
    uy = U(2*i);
    fprintf('节点 %d: ux = %.6f mm, uy = %.6f mm\n', i, ux, uy);
end

%% 13. 输出支座反力
disp('================ MATLAB 支座反力结果 ================');
for i = fixed_dof
    fprintf('自由度 %d 的反力 = %.3f N\n', i, R(i));
end

%% 14. 计算杆件轴力
% N = EA/L * [-c  -s   c   s] * ue
N_elem = zeros(nElem,1);

for e = 1:nElem
    n1 = elem(e,1);
    n2 = elem(e,2);

    Le = L_elem(e);
    c  = c_elem(e);
    s  = s_elem(e);

    dof = [2*n1-1, 2*n1, 2*n2-1, 2*n2];
    ue  = U(dof);

    N_elem(e) = E * A / Le * [-c, -s, c, s] * ue;
end

%% 15. 判断受拉或受压
disp('================ MATLAB 杆件轴力结果 ================');
for e = 1:nElem
    if N_elem(e) > 0
        state = '受拉';
    elseif N_elem(e) < 0
        state = '受压';
    else
        state = '零力杆';
    end

    fprintf('单元 %d: 轴力 N = %.3f N, %s\n', e, N_elem(e), state);
end

%% 16. 变形图
scale = 100;
node_def = node;

for i = 1:nNode
    node_def(i,1) = node(i,1) + scale * U(2*i-1);
    node_def(i,2) = node(i,2) + scale * U(2*i);
end

figure('Name','桁架变形图');
hold on; axis equal; grid on;
title(['桁架变形图，位移放大系数 = ', num2str(scale)]);
xlabel('x / mm'); ylabel('y / mm');

for e = 1:nElem
    n1 = elem(e,1);
    n2 = elem(e,2);

    plot(node([n1,n2],1), node([n1,n2],2), 'b-', 'LineWidth', 2);
    plot(node_def([n1,n2],1), node_def([n1,n2],2), 'r--', 'LineWidth', 1.5);
end

plot(node(:,1), node(:,2), 'bo', 'MarkerFaceColor', 'b');
plot(node_def(:,1), node_def(:,2), 'ro', 'MarkerFaceColor', 'r');
legend({'原结构','变形后结构','原节点','变形后节点'}, 'Location','best');

%% 17. 生成 Abaqus Python 建模、分析和后处理脚本
% Abaqus 脚本会完成：
% 1) 创建 2D planar truss wire part
% 2) 指定 T2D2 桁架单元、材料、截面
% 3) 施加节点1固定、节点2竖向约束、节点3竖向向下载荷
% 4) 提交 Job 并等待计算结束
% 5) 读取 ODB，导出位移、反力、单元应力与轴力 CSV

workDir = fileparts(mfilename('fullpath'));
if isempty(workDir)
    workDir = pwd;
end

abaqusPy = fullfile(workDir, 'truss2d_abaqus.py');
jobName  = 'Truss2D_Job';
modelName = 'Truss2D_Model';

writeAbaqusScript(abaqusPy, modelName, jobName, node, elem, E, A, P);
fprintf('\n已生成 Abaqus Python 脚本：%s\n', abaqusPy);

%% 18. 调用 Abaqus 运行分析
if runAbaqus
    oldDir = pwd;
    cleanupObj = onCleanup(@() cd(oldDir));
    cd(workDir);

    cmd = sprintf('abaqus cae noGUI="%s"', abaqusPy);
    fprintf('正在调用 Abaqus：%s\n', cmd);
    [status, cmdout] = system(cmd);

    if status ~= 0 || contains(cmdout, 'Abaqus Error')
        warning(['Abaqus 未成功运行。请确认 Abaqus 命令可用，或手动运行：\n', cmd]);
        disp(cmdout);
    else
        disp('Abaqus 分析与后处理完成。');
    end
else
    fprintf('runAbaqus = false，未自动运行。可手动执行：abaqus cae noGUI="%s"\n', abaqusPy);
end

%% 19. 读取 Abaqus 后处理结果并与 MATLAB 结果比较
dispCsv = fullfile(workDir, [jobName, '_displacement.csv']);
rfCsv   = fullfile(workDir, [jobName, '_reaction.csv']);
elemCsv = fullfile(workDir, [jobName, '_element_force.csv']);

if exist(dispCsv, 'file')
    abaqusU = readmatrix(dispCsv, 'NumHeaderLines', 1);
    disp('================ Abaqus 节点位移结果 ================');
    fprintf('节点号        U1/mm           U2/mm\n');
    fprintf('%4d   %14.6f   %14.6f\n', abaqusU(:,1:3).');

    if size(abaqusU,1) == nNode
        U_abaqus_vec = zeros(ndof,1);
        for k = 1:size(abaqusU,1)
            nid = abaqusU(k,1);
            U_abaqus_vec(2*nid-1) = abaqusU(k,2);
            U_abaqus_vec(2*nid)   = abaqusU(k,3);
        end
        fprintf('最大位移差值 |MATLAB - Abaqus| = %.6e mm\n', max(abs(U - U_abaqus_vec)));
    end
end

if exist(rfCsv, 'file')
    abaqusRF = readmatrix(rfCsv, 'NumHeaderLines', 1);
    disp('================ Abaqus 支座反力结果 ================');
    fprintf('节点号        RF1/N           RF2/N\n');
    fprintf('%4d   %14.6f   %14.6f\n', abaqusRF(:,1:3).');
end

if exist(elemCsv, 'file')
    abaqusElem = readmatrix(elemCsv, 'NumHeaderLines', 1);
    disp('================ Abaqus 单元应力与轴力结果 ================');
    fprintf('单元号      S11/MPa          轴力/N\n');
    fprintf('%4d   %14.6f   %14.6f\n', abaqusElem(:,1:3).');

    if size(abaqusElem,1) == nElem
        N_abaqus = zeros(nElem,1);
        for k = 1:size(abaqusElem,1)
            eid = abaqusElem(k,1);
            N_abaqus(eid) = abaqusElem(k,3);
        end
        fprintf('最大轴力差值 |MATLAB - Abaqus| = %.6e N\n', max(abs(N_elem - N_abaqus)));
    end
end

%% =========================================================
%  本脚本用到的局部函数
% =========================================================
function writeAbaqusScript(fileName, modelName, jobName, node, elem, E, A, P)
    fid = fopen(fileName, 'w');
    if fid < 0
        error('无法创建 Abaqus Python 脚本：%s', fileName);
    end
    c = onCleanup(@() fclose(fid));

    fprintf(fid, '# -*- coding: utf-8 -*-\n');
    fprintf(fid, 'from abaqus import *\n');
    fprintf(fid, 'from abaqusConstants import *\n');
    fprintf(fid, 'from odbAccess import openOdb\n');
    fprintf(fid, 'import mesh\n');
    fprintf(fid, 'import os\n\n');

    fprintf(fid, 'model_name = "%s"\n', modelName);
    fprintf(fid, 'job_name = "%s"\n', jobName);
    fprintf(fid, 'E = %.15g\n', E);
    fprintf(fid, 'A = %.15g\n', A);
    fprintf(fid, 'P = %.15g\n', P);

    fprintf(fid, 'nodes = [\n');
    for i = 1:size(node,1)
        fprintf(fid, '    (%d, %.15g, %.15g),\n', i, node(i,1), node(i,2));
    end
    fprintf(fid, ']\n');

    fprintf(fid, 'elements = [\n');
    for e = 1:size(elem,1)
        fprintf(fid, '    (%d, %d, %d),\n', e, elem(e,1), elem(e,2));
    end
    fprintf(fid, ']\n\n');

    fprintf(fid, 'if model_name in mdb.models:\n');
    fprintf(fid, '    del mdb.models[model_name]\n');
    fprintf(fid, 'model = mdb.Model(name=model_name)\n\n');

    fprintf(fid, 'part = model.Part(name="TrussPart", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)\n');
    fprintf(fid, 'node_xy = {label: (x, y, 0.0) for label, x, y in nodes}\n');
    fprintf(fid, 'for _, n1, n2 in elements:\n');
    fprintf(fid, '    part.WirePolyLine(points=(node_xy[n1], node_xy[n2]), mergeType=IMPRINT, meshable=ON)\n\n');

    fprintf(fid, 'model.Material(name="Steel")\n');
    fprintf(fid, 'model.materials["Steel"].Elastic(table=((E, 0.3),))\n');
    fprintf(fid, 'model.TrussSection(name="TrussSection", material="Steel", area=A)\n');
    fprintf(fid, 'part.SectionAssignment(region=part.Set(name="AllEdges", edges=part.edges[:]), sectionName="TrussSection")\n\n');

    fprintf(fid, 'for label, x, y in nodes:\n');
    fprintf(fid, '    v = part.vertices.findAt(((x, y, 0.0),))\n');
    fprintf(fid, '    part.Set(name="N%%d" %% label, vertices=v)\n\n');

    fprintf(fid, 'for label, n1, n2 in elements:\n');
    fprintf(fid, '    x1, y1, _ = node_xy[n1]\n');
    fprintf(fid, '    x2, y2, _ = node_xy[n2]\n');
    fprintf(fid, '    mx = 0.5 * (x1 + x2)\n');
    fprintf(fid, '    my = 0.5 * (y1 + y2)\n');
    fprintf(fid, '    edge = part.edges.findAt(((mx, my, 0.0),))\n');
    fprintf(fid, '    part.Set(name="E%%d" %% label, edges=edge)\n\n');

    fprintf(fid, 'part.seedPart(size=1000.0, deviationFactor=0.1, minSizeFactor=0.1)\n');
    fprintf(fid, 'elem_type = mesh.ElemType(elemCode=T2D2, elemLibrary=STANDARD)\n');
    fprintf(fid, 'part.setElementType(regions=(part.edges[:],), elemTypes=(elem_type,))\n');
    fprintf(fid, 'part.generateMesh()\n\n');

    fprintf(fid, 'assembly = model.rootAssembly\n');
    fprintf(fid, 'assembly.DatumCsysByDefault(CARTESIAN)\n');
    fprintf(fid, 'inst = assembly.Instance(name="TrussPart-1", part=part, dependent=ON)\n\n');

    fprintf(fid, 'model.StaticStep(name="LoadStep", previous="Initial", nlgeom=OFF)\n\n');

    fprintf(fid, 'model.DisplacementBC(name="BC_Node1_Fixed", createStepName="Initial", region=inst.sets["N1"], u1=0.0, u2=0.0, ur3=UNSET)\n');
    fprintf(fid, 'model.DisplacementBC(name="BC_Node2_UY", createStepName="Initial", region=inst.sets["N2"], u1=UNSET, u2=0.0, ur3=UNSET)\n');
    fprintf(fid, 'model.ConcentratedForce(name="Load_Node3_Down", createStepName="LoadStep", region=inst.sets["N3"], cf2=-P)\n\n');

    fprintf(fid, 'if job_name in mdb.jobs:\n');
    fprintf(fid, '    del mdb.jobs[job_name]\n');
    fprintf(fid, 'job = mdb.Job(name=job_name, model=model_name, description="2D truss analysis")\n');
    fprintf(fid, 'job.submit(consistencyChecking=OFF)\n');
    fprintf(fid, 'job.waitForCompletion()\n\n');

    fprintf(fid, 'odb_path = job_name + ".odb"\n');
    fprintf(fid, 'odb = openOdb(path=odb_path, readOnly=True)\n');
    fprintf(fid, 'step = odb.steps["LoadStep"]\n');
    fprintf(fid, 'frame = step.frames[-1]\n');
    fprintf(fid, 'inst_odb = odb.rootAssembly.instances["TRUSSPART-1"]\n\n');

    fprintf(fid, 'u_field = frame.fieldOutputs["U"]\n');
    fprintf(fid, 'rf_field = frame.fieldOutputs["RF"]\n');
    fprintf(fid, 'with open(job_name + "_displacement.csv", "w") as f:\n');
    fprintf(fid, '    f.write("Node,U1,U2\\n")\n');
    fprintf(fid, '    for label, _, _ in nodes:\n');
    fprintf(fid, '        region = inst_odb.nodeSets["N%%d" %% label]\n');
    fprintf(fid, '        val = u_field.getSubset(region=region).values[0].data\n');
    fprintf(fid, '        f.write("%%d,%%.12g,%%.12g\\n" %% (label, val[0], val[1]))\n\n');

    fprintf(fid, 'with open(job_name + "_reaction.csv", "w") as f:\n');
    fprintf(fid, '    f.write("Node,RF1,RF2\\n")\n');
    fprintf(fid, '    for label in (1, 2):\n');
    fprintf(fid, '        region = inst_odb.nodeSets["N%%d" %% label]\n');
    fprintf(fid, '        vals = rf_field.getSubset(region=region).values\n');
    fprintf(fid, '        if vals:\n');
    fprintf(fid, '            rf = vals[0].data\n');
    fprintf(fid, '            f.write("%%d,%%.12g,%%.12g\\n" %% (label, rf[0], rf[1]))\n\n');

    fprintf(fid, 's_field = frame.fieldOutputs["S"]\n');
    fprintf(fid, 'with open(job_name + "_element_force.csv", "w") as f:\n');
    fprintf(fid, '    f.write("Element,S11,AxialForce\\n")\n');
    fprintf(fid, '    for label, _, _ in elements:\n');
    fprintf(fid, '        region = inst_odb.elementSets["E%%d" %% label]\n');
    fprintf(fid, '        vals = s_field.getSubset(region=region).values\n');
    fprintf(fid, '        if vals:\n');
    fprintf(fid, '            s11 = vals[0].data[0]\n');
    fprintf(fid, '            f.write("%%d,%%.12g,%%.12g\\n" %% (label, s11, s11 * A))\n\n');

    fprintf(fid, 'odb.close()\n');
    fprintf(fid, 'print("Abaqus post-processing completed.")\n');
end
