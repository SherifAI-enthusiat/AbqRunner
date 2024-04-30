# import subprocess
# import os

# os.mkdir("workspace/temp-SGE_TASK_ID")

# pca = subprocess.run("runAbaqus.sh",shell=True,text=True)
# print("Done")
# test = "0.01,0.01,1,0.01,0.01,0.01,1,1,1,"
# test = test.split(',')
# for it in range(len(test)):
#     try:
#         print(test(it))
#     except:
#         continue
######################### Reads code from HPC ##########################
import HelperFunc as Hp
import numpy as np
import subprocess,os,shutil
import glob
cwdir = os.path.dirname(__file__)
# expData = np.genfromtxt("compData.txt")

def ReadWriteOdb(filePath):
    paths = Hp.definePaths(filePath)
    if os.path.exists(paths[0]):
        shutil.rmtree(os.path.dirname(paths[0]))
    dataRet = os.path.join(os.getcwd(),"readOdb.py")
    command = 'abaqus python "%s"'%dataRet
    commandn = r'%s -- "%s"'%(command,filePath)
    pcall = subprocess.call(commandn,shell=True)
    return

def findParameters(lines):
    for ind,item in enumerate(lines):
        if item.startswith('*Material') and item.endswith('PM_MENISCAL_MEN\n'):
            coef = lines[ind+2].strip("\n")
            break
    return coef

Directory = "E:\Optimisation - Thesis studies\Knee 5"
findFiles = glob.glob(Directory + "\workspace_*\TestJob-2.inp")
tmp = []
for ind,val in enumerate(findFiles):
    lines = Hp.fileReader(val)
    tmp.append(findParameters(lines))
    # To write results files
    val = val.strip("\\TestJob-2.inp")
    # newVal = glob.glob(val + "genOdb*.odb")
    # newVal1 = glob.glob(val + "PCKnee*.odb")
    ReadWriteOdb(val)
tmp = np.vstack(tmp)
np.savetxt("compData.txt",tmp,delimiter=',')

##############################################################
# import HelperFunc as Hp
# import os
# import write2InpFile as w2p
# # cwdir = "E:\Optimisation - Thesis studies\HPC\Knee 5\workspace\wemp-997" 
# # cwdir = os.path.join(cwdir,"TestJob-2.inp")
# # Hp.findParameters(cwdir)
# # test = Hp.findFiles()
# x =[0.01, 0.01, 1.0, 0.01, 0.01, 0.01, 8.6, 18.4, 18.4]
# orifile = "TestJob-2.inp"
# workspacePath = "MatlabOutput"
# w2p.writeInp(x,orifile,workspacePath,orifile)

