#!/bin/bash
#$ -l h_rt=5:00:00
##This uses GPU
##$ -l coproc_v100=1
#This uses threads
#$ -pe smp 4
#$ -l h_vmem=4G
# specify a task array of 1500 tasks
#$ -t 1-3780:8
# limit of 13 tasks at one time to constrain license token use to 156 token (12*13)
#$ -tc 6
unset GOMP_CPU_AFFINITY KMP_AFFINIT
module load anaconda
source activate base
module add abaqus/2022
export LM_LICENSE_FILE=27004@abaqus-server1.leeds.ac.uk:$LM_LICENSE_FILE
export ABAQUSLM_LICENSE_FILE=$LM_LICENSE_FILE
param=$(sed -n -e "$SGE_TASK_ID p" param_values.csv)
export FileName='TestJob-2.inp'
workspacePath=/nobackup/mnsaz/AbqRunner/workspace/temp-$SGE_TASK_ID 
export inpPath=$workspacePath/$FileName
mkdir -p $workspacePath
python write2InpFile.py "$param" "$FileName" "$workspacePath" "$FileName"
cd workspace/temp-$SGE_TASK_ID
abaqus memory='20000mb' cpus="$NSLOTS" input="$inpPath" job="PCKnee" mp_mode=threads int
# This will be used to read the output and store to file
python <<-EOF
import os
import subprocess
absPath = os.path.dirname(__file__)
dataRet = os.path.join(absPath,"dataRetrieval.py")
command = 'abaqus python "%s"'%dataRet
os.chdir(absPath)
commandn = r'%s -- "%s"'%(command,workspacePath)
pCall2 = subprocess.run(commandn, shell= True)
EOF
