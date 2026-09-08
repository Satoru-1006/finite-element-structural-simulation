# -*- coding: utf-8 -*-
from abaqus import *
from abaqusConstants import *
from odbAccess import openOdb
import mesh
import os

model_name = "Truss2D_Model"
job_name = "Truss2D_Job"
E = 200000
A = 300
P = 10000
nodes = [
    (1, 0, 0),
    (2, 1000, 0),
    (3, 500, 800),
]
elements = [
    (1, 1, 2),
    (2, 1, 3),
    (3, 2, 3),
]

if model_name in mdb.models:
    del mdb.models[model_name]
model = mdb.Model(name=model_name)

part = model.Part(name="TrussPart", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)
node_xy = {label: (x, y, 0.0) for label, x, y in nodes}
for _, n1, n2 in elements:
    part.WirePolyLine(points=(node_xy[n1], node_xy[n2]), mergeType=IMPRINT, meshable=ON)

model.Material(name="Steel")
model.materials["Steel"].Elastic(table=((E, 0.3),))
model.TrussSection(name="TrussSection", material="Steel", area=A)
part.SectionAssignment(region=part.Set(name="AllEdges", edges=part.edges[:]), sectionName="TrussSection")

for label, x, y in nodes:
    v = part.vertices.findAt(((x, y, 0.0),))
    part.Set(name="N%d" % label, vertices=v)

for label, n1, n2 in elements:
    x1, y1, _ = node_xy[n1]
    x2, y2, _ = node_xy[n2]
    mx = 0.5 * (x1 + x2)
    my = 0.5 * (y1 + y2)
    edge = part.edges.findAt(((mx, my, 0.0),))
    part.Set(name="E%d" % label, edges=edge)

part.seedPart(size=1000.0, deviationFactor=0.1, minSizeFactor=0.1)
elem_type = mesh.ElemType(elemCode=T2D2, elemLibrary=STANDARD)
part.setElementType(regions=(part.edges[:],), elemTypes=(elem_type,))
part.generateMesh()

assembly = model.rootAssembly
assembly.DatumCsysByDefault(CARTESIAN)
inst = assembly.Instance(name="TrussPart-1", part=part, dependent=ON)

model.StaticStep(name="LoadStep", previous="Initial", nlgeom=OFF)

model.DisplacementBC(name="BC_Node1_Fixed", createStepName="Initial", region=inst.sets["N1"], u1=0.0, u2=0.0, ur3=UNSET)
model.DisplacementBC(name="BC_Node2_UY", createStepName="Initial", region=inst.sets["N2"], u1=UNSET, u2=0.0, ur3=UNSET)
model.ConcentratedForce(name="Load_Node3_Down", createStepName="LoadStep", region=inst.sets["N3"], cf2=-P)

if job_name in mdb.jobs:
    del mdb.jobs[job_name]
job = mdb.Job(name=job_name, model=model_name, description="2D truss analysis")
job.submit(consistencyChecking=OFF)
job.waitForCompletion()

odb_path = job_name + ".odb"
odb = openOdb(path=odb_path, readOnly=True)
step = odb.steps["LoadStep"]
frame = step.frames[-1]
inst_odb = odb.rootAssembly.instances["TRUSSPART-1"]

u_field = frame.fieldOutputs["U"]
rf_field = frame.fieldOutputs["RF"]
with open(job_name + "_displacement.csv", "w") as f:
    f.write("Node,U1,U2\n")
    for label, _, _ in nodes:
        region = inst_odb.nodeSets["N%d" % label]
        val = u_field.getSubset(region=region).values[0].data
        f.write("%d,%.12g,%.12g\n" % (label, val[0], val[1]))

with open(job_name + "_reaction.csv", "w") as f:
    f.write("Node,RF1,RF2\n")
    for label in (1, 2):
        region = inst_odb.nodeSets["N%d" % label]
        vals = rf_field.getSubset(region=region).values
        if vals:
            rf = vals[0].data
            f.write("%d,%.12g,%.12g\n" % (label, rf[0], rf[1]))

s_field = frame.fieldOutputs["S"]
with open(job_name + "_element_force.csv", "w") as f:
    f.write("Element,S11,AxialForce\n")
    for label, _, _ in elements:
        region = inst_odb.elementSets["E%d" % label]
        vals = s_field.getSubset(region=region).values
        if vals:
            s11 = vals[0].data[0]
            f.write("%d,%.12g,%.12g\n" % (label, s11, s11 * A))

odb.close()
print("Abaqus post-processing completed.")
