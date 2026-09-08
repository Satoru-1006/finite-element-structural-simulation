from abaqus import *
from abaqusConstants import *
import os
out_dir = r'C:/Users/86198/Desktop/task6.1'
odb_path = os.path.join(out_dir, 'Task3_A_PortalFrame_SFSM.odb')
session.openOdb(name=odb_path)
odb = session.odbs[odb_path]
vp = session.Viewport(name='Viewport: 1', origin=(0,0), width=180, height=120)
vp.setValues(displayedObject=odb)
vp.odbDisplay.display.setValues(plotState=(DEFORMED,))
vp.view.fitView()
session.printOptions.setValues(vpDecorations=OFF)
session.pngOptions.setValues(imageSize=(1600,1200))
session.printToFile(fileName=os.path.join(out_dir,'A_deformed_shape'), format=PNG, canvasObjects=(vp,))
vp.odbDisplay.display.setValues(plotState=(CONTOURS_ON_DEF,))
vp.odbDisplay.setPrimaryVariable(variableLabel='SM', outputPosition=INTEGRATION_POINT, refinement=(COMPONENT, 'SM3'))
vp.view.fitView()
session.printToFile(fileName=os.path.join(out_dir,'A_bending_moment_SM3'), format=PNG, canvasObjects=(vp,))
vp.odbDisplay.setPrimaryVariable(variableLabel='SF', outputPosition=INTEGRATION_POINT, refinement=(COMPONENT, 'SF1'))
vp.view.fitView()
session.printToFile(fileName=os.path.join(out_dir,'A_axial_force_SF1'), format=PNG, canvasObjects=(vp,))
print('exported')
