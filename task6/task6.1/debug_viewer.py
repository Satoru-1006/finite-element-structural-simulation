from abaqus import *
from abaqusConstants import *
import os
out_dir = r'C:/Users/86198/Desktop/task6.1'
odb_path = os.path.join(out_dir, 'Task3_A_PortalFrame_SFSM.odb')
odb = session.openOdb(name=odb_path)
print('VIEWPORTS', session.viewports.keys())
print('ODB TYPE', type(odb))
print('SESSION ODB TYPE', type(session.odbs[odb_path]))
