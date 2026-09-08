from abaqus import *
from abaqusConstants import *
openMdb(pathName=r'C:/Users/86198/Desktop/task6.1/task6.1_subtask3.cae')
model = mdb.models['Task3_A_PortalFrame']
print(type(model))
print([a for a in dir(model) if 'Output' in a or 'output' in a])
print(model.steps.keys())
