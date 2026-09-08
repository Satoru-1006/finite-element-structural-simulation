# -*- coding: mbcs -*-
#
# Abaqus/Viewer Release 2026 replay file
# Internal Version: 2025_09_23-22.43.03 RELr428 206049
# Run by zxj on Mon May 18 11:14:21 2026
#

# from driverUtils import executeOnCaeGraphicsStartup
# executeOnCaeGraphicsStartup()
#: Executing "onCaeGraphicsStartup()" in the site directory ...
from abaqus import *
from abaqusConstants import *
session.Viewport(name='Viewport: 1', origin=(1.11979, 1.11979), width=164.833, 
    height=111.083)
session.viewports['Viewport: 1'].makeCurrent()
from driverUtils import executeOnCaeStartup
executeOnCaeStartup()
#: Executing "onCaeStartup()" in the home directory ...
#: =======================================================
#: Abaqus MCP Plugin v4.0.0 (File IPC)
#: =======================================================
#: Home:   D:\mcp
#: Abaqus: True
#: Start:  mcp_start()     (background, recommended)
#:         mcp_loop()      (blocking)
#: Stop:   mcp_stop()
#: Status: mcp_status()
#: =======================================================
execfile('C:/Users/86198/Desktop/task6.1/debug_viewer.py', __main__.__dict__)
#: Model: C:/Users/86198/Desktop/task6.1/Task3_A_PortalFrame_SFSM.odb
#: Number of Assemblies:         1
#: Number of Assembly instances: 0
#: Number of Part instances:     1
#: Number of Meshes:             1
#: Number of Element Sets:       1
#: Number of Node Sets:          4
#: Number of Steps:              1
#: VIEWPORTS ['Viewport: 1']
#: ODB TYPE <class 'abaqus.Odb'>
#: SESSION ODB TYPE <class 'abaqus.Odb'>
print('RT script done')
#: RT script done
