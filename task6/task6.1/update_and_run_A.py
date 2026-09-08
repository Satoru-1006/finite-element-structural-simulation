from abaqus import *
from abaqusConstants import *
import os
openMdb(pathName=r'C:/Users/86198/Desktop/task6.1/task6.1_subtask3.cae')
model = mdb.models['Task3_A_PortalFrame']
model.fieldOutputRequests['F-Output-1'].setValues(variables=('U','RF','S','SF','SM'))
mdb.saveAs(pathName=r'C:/Users/86198/Desktop/task6.1/task6.1_subtask3.cae')
job = mdb.jobs['Task3_A_PortalFrame']
job.submit(consistencyChecking=OFF)
job.waitForCompletion()
print('JOB_STATUS', job.status)
