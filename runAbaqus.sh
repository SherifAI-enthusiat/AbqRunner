#!/bin/bash
#$ -l h_rt=5:00:00
##This uses GPU
##$ -l coproc_v100=1
#This uses threads
#$ -pe smp 4
#$ -l h_vmem=4G
# specify a task array of 1500 tasks
#$ -t 1-296751:250
# limit of 13 tasks at one time to constrain license token use to 156 token (12*13)
#$ -tc 6
unset GOMP_CPU_AFFINITY KMP_AFFINIT
module load anaconda
source activate base
module add abaqus
python <<-EOF
import glob
files = glob.glob("InpFiles/*.inp")
EOF
rm -r /nobackup/mnsaz/Mengoni_tool/workspace/temp-$SGE_TASK_ID
export LM_LICENSE_FILE=27004@abaqus-server1.leeds.ac.uk:$LM_LICENSE_FILE
infile=$(sed -n -e "$SGE_TASK_ID p" param_values.ascii)
export FileName='TestJob-2.inp'
temp = /nobackup/mnsaz/AbqRunner/workspace/temp-$SGE_TASK_ID 
mkdir -p "$temp"
python write2InpFile.py $infile $SGE_TASK_ID $temp $FileName
cd workspace/temp-$SGE_TASK_ID
abaqus memory='20000mb' cpus='4' input="${FileName}.inp" job=$FileName mp_mode=threads
# python <<-EOF
# import subprocess
# subprocess.call('abaqus cae noGUI="/nobackup/mnsaz/Mengoni_tool/readOutput.py" -- $FileName "workspace/temp-$SGE_TASK_ID" $infile',shell=True)
# EOF
# rm -r /nobackup/mnsaz/Mengoni_tool/workspace/temp-$SGE_TASK_ID