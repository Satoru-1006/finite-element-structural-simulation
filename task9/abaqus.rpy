# -*- coding: mbcs -*-
#
# Abaqus/CAE Release 2026 replay file
# Internal Version: 2025_09_23-22.43.03 RELr428 206049
# Run by zxj on Wed Jun  3 10:54:32 2026
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
execfile('C:/Users/86198/Desktop/task9/task9_abaqus_model.py', 
    __main__.__dict__)
#: The model "Task9_Rectangular_Plate_Tension" has been created.
#: The model database has been saved to "C:\Users\86198\Desktop\task9\task9_rect_plate_tension.cae".
#: Model: C:/Users/86198/Desktop/task9/task9_rect_plate_tension.odb
#: Number of Assemblies:         1
#: Number of Assembly instances: 0
#: Number of Part instances:     1
#: Number of Meshes:             1
#: Number of Element Sets:       4
#: Number of Node Sets:          13
#: Number of Steps:              1
#: TASK9_DONE
#: {
#:   "parameters": {
#:     "L_m": 1.0,
#:     "H_m": 0.4,
#:     "t_m": 0.01,
#:     "E_Pa": 210000000000.0,
#:     "nu": 0.3,
#:     "q_Pa": 100000000.0,
#:     "mesh_size_m": 0.05,
#:     "element_type": "CPS3",
#:     "analysis": "Static General, plane stress"
#:   },
#:   "mesh": {
#:     "node_count": 189,
#:     "element_count": 320,
#:     "right_edge_node_count": 9
#:   },
#:   "load": {
#:     "equivalent_total_force_N": 400000.0059604645,
#:     "expected_total_force_N": 400000.0
#:   },
#:   "theory": {
#:     "sigma_x_Pa": 100000000.0,
#:     "sigma_y_Pa": 0.0,
#:     "tau_xy_Pa": 0.0,
#:     "epsilon_x": 0.0004761904761904762,
#:     "epsilon_y": -0.00014285714285714287,
#:     "gamma_xy": 0.0,
#:     "u_right_m": 0.0004761904761904762
#:   },
#:   "abaqus_results": {
#:     "U1_max_m": 0.0004743839428388635,
#:     "U1_right_avg_m": 0.0004733363377319679,
#:     "U1_right_error_percent": 0.5993690762867374,
#:     "S11_mid_avg_Pa": 100179205.15451367,
#:     "S11_mid_error_percent": 0.17920515451367197,
#:     "left_region_abs_avg_S11_Pa": 99999998.45990987,
#:     "left_region_abs_avg_S22_Pa": 12749986.6952692,
#:     "left_region_abs_avg_S12_Pa": 4817509.9267440345
#:   }
#: }
print('RT script done')
#: RT script done
