from odbAccess import openOdb
import csv, os
odb = openOdb(path=r'C:/Users/86198/Desktop/task6.1/Task3_A_PortalFrame_SFSM.odb', readOnly=True)
frame = odb.steps['LoadStep'].frames[-1]
inst = odb.rootAssembly.instances['PORTALFRAME-1']
out_dir = r'C:/Users/86198/Desktop/task6.1'
# nodes
with open(os.path.join(out_dir,'A_nodes.csv'),'w') as f:
    w=csv.writer(f); w.writerow(['label','x','y','u1','u2'])
    for n in inst.nodes:
        u = frame.fieldOutputs['U'].getSubset(region=n).values[0].data
        w.writerow([n.label,n.coordinates[0],n.coordinates[1],u[0],u[1]])
# elements connectivity
with open(os.path.join(out_dir,'A_elements.csv'),'w') as f:
    w=csv.writer(f); w.writerow(['label','n1','n2','sf1','sf2','sm3'])
    sf = {v.elementLabel:v.data for v in frame.fieldOutputs['SF'].values}
    sm = {v.elementLabel:v.data for v in frame.fieldOutputs['SM'].values}
    for e in inst.elements:
        w.writerow([e.label,e.connectivity[0],e.connectivity[1],sf[e.label][0],sf[e.label][1],sm[e.label][0]])
odb.close()
