# -*- coding: mbcs -*-
"""
Abaqus/CAE noGUI script for FEM course task 9.

It builds and solves a 2D plane-stress rectangular plate under tension, then
exports displacement/stress CSV files, a JSON summary, and result figures.

Run in Abaqus:
    abaqus cae noGUI=task9_abaqus_model.py
"""

from abaqus import *
from abaqusConstants import *
import mesh
import visualization
import os
import csv
import json
import math


OUT_DIR = r"C:\Users\86198\Desktop\task9"
MODEL_NAME = "Task9_Rectangular_Plate_Tension"
JOB_NAME = "task9_rect_plate_tension"

L = 1.0
H = 0.4
t = 0.01
E = 210.0e9
nu = 0.30
q = 100.0e6
mesh_size = 0.05


def ensure_dir(path):
    if not os.path.isdir(path):
        os.makedirs(path)


def remove_old_job_files():
    exts = [
        ".odb", ".inp", ".dat", ".msg", ".sta", ".com", ".prt", ".sim",
        ".log", ".lck", ".cae"
    ]
    for ext in exts:
        p = os.path.join(OUT_DIR, JOB_NAME + ext)
        if os.path.exists(p):
            try:
                os.remove(p)
            except Exception:
                pass


def write_csv(path, header, rows):
    f = open(path, "w", newline="")
    try:
        writer = csv.writer(f)
        writer.writerow(header)
        for row in rows:
            writer.writerow(row)
    finally:
        f.close()


def make_model():
    ensure_dir(OUT_DIR)
    remove_old_job_files()
    os.chdir(OUT_DIR)

    if MODEL_NAME in mdb.models.keys():
        del mdb.models[MODEL_NAME]
    model = mdb.Model(name=MODEL_NAME)

    sketch = model.ConstrainedSketch(name="plate_profile", sheetSize=2.0)
    sketch.rectangle(point1=(0.0, 0.0), point2=(L, H))
    part = model.Part(name="Plate", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)
    part.BaseShell(sketch=sketch)

    material = model.Material(name="Steel_linear_elastic")
    material.Elastic(table=((E, nu),))
    model.HomogeneousSolidSection(
        name="Plane_stress_section",
        material="Steel_linear_elastic",
        thickness=t
    )

    faces = part.faces[:]
    region = part.Set(name="Plate_all", faces=faces)
    part.SectionAssignment(region=region, sectionName="Plane_stress_section")

    part.seedPart(size=mesh_size, deviationFactor=0.1, minSizeFactor=0.1)
    part.setMeshControls(regions=faces, elemShape=TRI, technique=FREE)
    elem_type = mesh.ElemType(elemCode=CPS3, elemLibrary=STANDARD)
    part.setElementType(regions=(faces,), elemTypes=(elem_type,))
    part.generateMesh()

    assembly = model.rootAssembly
    assembly.DatumCsysByDefault(CARTESIAN)
    inst = assembly.Instance(name="Plate-1", part=part, dependent=ON)

    tol = mesh_size * 0.20
    left_edges = inst.edges.getByBoundingBox(
        xMin=-tol, xMax=tol, yMin=-tol, yMax=H + tol
    )
    right_edges = inst.edges.getByBoundingBox(
        xMin=L - tol, xMax=L + tol, yMin=-tol, yMax=H + tol
    )
    assembly.Set(name="LeftEdge", edges=left_edges)
    assembly.Set(name="RightEdge", edges=right_edges)

    model.StaticStep(name="Load", previous="Initial", nlgeom=OFF)
    model.DisplacementBC(
        name="BC_Left_Fixed",
        createStepName="Initial",
        region=assembly.sets["LeftEdge"],
        u1=0.0,
        u2=0.0,
        ur3=UNSET,
        amplitude=UNSET,
        distributionType=UNIFORM,
        fieldName="",
        localCsys=None
    )

    # Equivalent nodal line load for the right edge:
    # nodal force = q * thickness * tributary edge length.
    right_nodes = []
    for node in inst.nodes:
        x, y, z = node.coordinates
        if abs(x - L) <= tol:
            right_nodes.append(node)
    right_nodes.sort(key=lambda n: n.coordinates[1])

    total_force = 0.0
    n_right = len(right_nodes)
    for i, node in enumerate(right_nodes):
        y = node.coordinates[1]
        if n_right == 1:
            weight = H
        elif i == 0:
            weight = 0.5 * (right_nodes[i + 1].coordinates[1] - y)
        elif i == n_right - 1:
            weight = 0.5 * (y - right_nodes[i - 1].coordinates[1])
        else:
            weight = 0.5 * (
                right_nodes[i + 1].coordinates[1] -
                right_nodes[i - 1].coordinates[1]
            )
        cf = q * t * weight
        total_force += cf
        set_name = "RightNode_%d" % node.label
        assembly.Set(name=set_name, nodes=inst.nodes.sequenceFromLabels((node.label,)))
        model.ConcentratedForce(
            name="Load_Right_%d" % node.label,
            createStepName="Load",
            region=assembly.sets[set_name],
            cf1=cf
        )

    job = mdb.Job(
        name=JOB_NAME,
        model=MODEL_NAME,
        description="Task 9 rectangular plane-stress plate tension",
        type=ANALYSIS,
        explicitPrecision=SINGLE,
        nodalOutputPrecision=FULL,
        multiprocessingMode=DEFAULT,
        numCpus=1,
        numDomains=1
    )

    return model, part, assembly, inst, job, total_force


def capture_png(viewport, file_name):
    try:
        viewport.viewportAnnotationOptions.setValues(
            triad=OFF,
            legend=OFF,
            title=OFF,
            state=OFF,
            annotations=OFF,
            compass=OFF
        )
    except Exception:
        pass
    session.printOptions.setValues(vpDecorations=OFF, vpBackground=OFF)
    session.pngOptions.setValues(imageSize=(1600, 1100))
    session.printToFile(
        fileName=os.path.join(OUT_DIR, os.path.splitext(file_name)[0]),
        format=PNG,
        canvasObjects=(viewport,)
    )


def save_mesh_picture(part):
    vp = session.Viewport(name="Task9_mesh", origin=(0, 0), width=180, height=120)
    vp.setValues(displayedObject=part)
    vp.partDisplay.setValues(mesh=ON)
    vp.partDisplay.meshOptions.setValues(meshTechnique=ON)
    vp.view.fitView()
    capture_png(vp, "mesh.png")


def set_primary_variable_and_capture(vp, odb, label, variable, component=None):
    vp.setValues(displayedObject=odb)
    vp.odbDisplay.display.setValues(plotState=(CONTOURS_ON_DEF,))
    if component:
        vp.odbDisplay.setPrimaryVariable(
            variableLabel=variable,
            outputPosition=NODAL if variable == "U" else INTEGRATION_POINT,
            refinement=(COMPONENT, component)
        )
    else:
        vp.odbDisplay.setPrimaryVariable(
            variableLabel=variable,
            outputPosition=NODAL if variable == "U" else INTEGRATION_POINT
        )
    vp.view.fitView()
    capture_png(vp, label)


def save_deformed_picture(vp, odb):
    vp.setValues(displayedObject=odb)
    vp.odbDisplay.display.setValues(plotState=(DEFORMED,))
    vp.view.fitView()
    capture_png(vp, "deformed_shape.png")


def value_data(value):
    try:
        return value.data
    except Exception:
        return value.dataDouble


def process_results(total_force):
    odb_path = os.path.join(OUT_DIR, JOB_NAME + ".odb")
    odb = session.openOdb(name=odb_path)
    step = odb.steps["Load"]
    frame = step.frames[-1]
    inst = odb.rootAssembly.instances["PLATE-1"]

    coord_by_label = {}
    for node in inst.nodes:
        coord_by_label[node.label] = node.coordinates

    u_field = frame.fieldOutputs["U"]
    disp_rows = []
    u1_max = -1.0e99
    right_u1 = []
    tol = mesh_size * 0.20
    for value in u_field.values:
        label = value.nodeLabel
        x, y, z = coord_by_label[label]
        data = value_data(value)
        u1 = data[0]
        u2 = data[1]
        if u1 > u1_max:
            u1_max = u1
        if abs(x - L) <= tol:
            right_u1.append(u1)
        disp_rows.append([label, x, y, u1, u2])
    write_csv(
        os.path.join(OUT_DIR, "node_displacements.csv"),
        ["node", "x", "y", "U1", "U2"],
        disp_rows
    )

    s_field = frame.fieldOutputs["S"]
    stress_rows = []
    mid_s11 = []
    left_stress = []
    for value in s_field.values:
        elem = inst.getElementFromLabel(value.elementLabel)
        xs = []
        ys = []
        for nlabel in elem.connectivity:
            x, y, z = coord_by_label[nlabel]
            xs.append(x)
            ys.append(y)
        cx = sum(xs) / len(xs)
        cy = sum(ys) / len(ys)
        data = value_data(value)
        s11 = data[0]
        s22 = data[1]
        s12 = data[3]
        stress_rows.append([
            value.elementLabel, value.integrationPoint, cx, cy, s11, s22, s12
        ])
        if 0.45 * L <= cx <= 0.55 * L and 0.35 * H <= cy <= 0.65 * H:
            mid_s11.append(s11)
        if cx <= 0.15 * L:
            left_stress.append((s11, s22, s12))
    write_csv(
        os.path.join(OUT_DIR, "element_stresses.csv"),
        ["element", "integration_point", "centroid_x", "centroid_y", "S11", "S22", "S12"],
        stress_rows
    )

    right_u1_avg = sum(right_u1) / len(right_u1)
    u_right_theory = q * L / E
    error = abs(right_u1_avg - u_right_theory) / u_right_theory * 100.0
    mid_s11_avg = sum(mid_s11) / len(mid_s11)
    mid_s11_error = abs(mid_s11_avg - q) / q * 100.0
    left_abs_avg = [0.0, 0.0, 0.0]
    if left_stress:
        left_abs_avg = [
            sum([abs(v[i]) for v in left_stress]) / len(left_stress)
            for i in range(3)
        ]

    summary = {
        "parameters": {
            "L_m": L,
            "H_m": H,
            "t_m": t,
            "E_Pa": E,
            "nu": nu,
            "q_Pa": q,
            "mesh_size_m": mesh_size,
            "element_type": "CPS3",
            "analysis": "Static General, plane stress"
        },
        "mesh": {
            "node_count": len(inst.nodes),
            "element_count": len(inst.elements),
            "right_edge_node_count": len(right_u1)
        },
        "load": {
            "equivalent_total_force_N": total_force,
            "expected_total_force_N": q * t * H
        },
        "theory": {
            "sigma_x_Pa": q,
            "sigma_y_Pa": 0.0,
            "tau_xy_Pa": 0.0,
            "epsilon_x": q / E,
            "epsilon_y": -nu * q / E,
            "gamma_xy": 0.0,
            "u_right_m": u_right_theory
        },
        "abaqus_results": {
            "U1_max_m": u1_max,
            "U1_right_avg_m": right_u1_avg,
            "U1_right_error_percent": error,
            "S11_mid_avg_Pa": mid_s11_avg,
            "S11_mid_error_percent": mid_s11_error,
            "left_region_abs_avg_S11_Pa": left_abs_avg[0],
            "left_region_abs_avg_S22_Pa": left_abs_avg[1],
            "left_region_abs_avg_S12_Pa": left_abs_avg[2]
        }
    }
    f = open(os.path.join(OUT_DIR, "results_summary.json"), "w")
    try:
        json.dump(summary, f, indent=2)
    finally:
        f.close()

    vp = session.Viewport(name="Task9_results", origin=(0, 0), width=180, height=120)
    set_primary_variable_and_capture(vp, odb, "U1.png", "U", "U1")
    set_primary_variable_and_capture(vp, odb, "U2.png", "U", "U2")
    set_primary_variable_and_capture(vp, odb, "S11.png", "S", "S11")
    set_primary_variable_and_capture(vp, odb, "S22.png", "S", "S22")
    set_primary_variable_and_capture(vp, odb, "S12.png", "S", "S12")
    save_deformed_picture(vp, odb)
    odb.close()
    return summary


def main():
    model, part, assembly, inst, job, total_force = make_model()
    save_mesh_picture(part)
    mdb.saveAs(pathName=os.path.join(OUT_DIR, JOB_NAME + ".cae"))
    job.submit()
    job.waitForCompletion()
    summary = process_results(total_force)
    print("TASK9_DONE")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
