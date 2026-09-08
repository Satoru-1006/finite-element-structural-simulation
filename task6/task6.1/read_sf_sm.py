from odbAccess import openOdb
odb = openOdb(path=r'C:/Users/86198/Desktop/task6.1/Task3_A_PortalFrame_SFSM.odb', readOnly=True)
frame = odb.steps['LoadStep'].frames[-1]
print(frame.fieldOutputs.keys())
for key in ['SF','SM']:
    vals = frame.fieldOutputs[key].values
    print(key, len(vals))
    for v in vals:
        print(v.elementLabel, v.integrationPoint, v.data)
odb.close()
