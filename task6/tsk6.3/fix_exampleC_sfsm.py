from abaqus import *
from abaqusConstants import *
import os
cae_path = r'C:/Users/86198/Desktop/tsk6.3/exampleC_space_frame.cae'
openMdb(pathName=cae_path)
model = mdb.models['ExampleC_SpaceFrame']
# Insert SF and SM element field output through keyword block so they are written to the ODB.
model.keywordBlock.synchVersions(storeNodesAndElements=False)
blocks = list(model.keywordBlock.sieBlocks)
# Avoid duplicate insertion if script is run twice.
joined = '\n'.join(blocks)
if 'SF, SM' not in joined:
    insert_at = None
    for i, line in enumerate(blocks):
        if line.strip().lower().startswith('*output, field'):
            insert_at = i + 1
            break
    if insert_at is None:
        raise RuntimeError('Could not find field output block')
    model.keywordBlock.insert(insert_at, '*Element Output, directions=YES\nSF, SM')
# Remove old fixed job if exists and create a new one.
job_name = 'ExampleC_SpaceFrame_SFSM'
if job_name in mdb.jobs.keys():
    del mdb.jobs[job_name]
mdb.Job(name=job_name, model='ExampleC_SpaceFrame', type=ANALYSIS,
        description='Example C with beam section force SF and section moment SM field output',
        numCpus=1, numDomains=1)
mdb.saveAs(pathName=cae_path)
print('Saved fixed CAE:', cae_path)
print('Job:', job_name)
