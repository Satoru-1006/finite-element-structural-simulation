# -*- coding: mbcs -*-
#
# Abaqus/CAE Release 2026 replay file
# Internal Version: 2025_09_23-22.43.03 RELr428 206049
# Run by zxj on Thu May 21 00:32:06 2026
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
execfile('C:/Users/86198/Desktop/tsk6.3/fix_exampleC_sfsm.py', 
    __main__.__dict__)
#: A new model database has been created.
#: The model "Model-1" has been created.
session.viewports['Viewport: 1'].setValues(displayedObject=None)
#* ****ERROR: Transcoding Error: *** Error: File open failed (utl_File: 
#* CreateFile in OpenUpdate)
#* error: 另一个程序正在使用此文件，进程无法访问。
#* 
#* file: C:\Users\86198\Desktop\tsk6.3\exampleC_space_frame.cae
#* File "C:/Users/86198/Desktop/tsk6.3/fix_exampleC_sfsm.py", line 5, in 
#* <module>
#*     openMdb(pathName=cae_path)
