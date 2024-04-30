import os,time
import random
# import glob
# from tkinter import messagebox
# import psutil, shutil
# from scipy.io import savemat
import numpy as np
import glob
# from pathlib import Path
# from queue import Queue

## Paths
# process_queue = Queue(maxsize=1)
basePath =os.getcwd()
os.chdir(basePath)
MatlabOutput = os.path.join(basePath,"MatlabOutput")
queFile = os.path.join(basePath,"WorkQueue.ascii")
OdbqueFile = os.path.join(basePath,"OdbQueue.ascii")
RunDir = os.path.join(basePath,"RunDir")

def findFiles(path):
    tmpPath = []
    cwdir = path +"\*\Results\latEpiCoordData.txt"
    findFiles =  glob.glob(cwdir)
    for _,itm in enumerate(findFiles):
        path = os.path.dirname(itm)
        tmpPath.append(path)
    return tmpPath

def definePaths(workspacePath):
    medEpiCoordPath = os.path.join(workspacePath,"Results\medEpiCoordData.txt")
    latEpiCoordPath = os.path.join(workspacePath,"Results\latEpiCoordData.txt")
    medDisplPath = os.path.join(workspacePath,"Results\medDisplData.txt")
    latDisplPath = os.path.join(workspacePath,"Results\latDisplData.txt")
    odbFile = os.path.join(workspacePath,"genOdb_%s.odb"%(workspacePath.split("_")[-1]))
    newls = [medEpiCoordPath,latEpiCoordPath,medDisplPath,latDisplPath,odbFile]
    return newls

def checkInpfile(kneeName):
    lines = fileReader("TestJob-2.inp")
    it =0; value = False
    for it,val in enumerate(lines):
        if val.startswith('** Job name:'):
            var = 'PC'+kneeName.replace(' ','')
            if var in val:
                value = True
                break
    return value

def write2File(outFile,dictn1):
    with open(outFile,'a') as datFile_1:
        tempN1= np.array([dictn1]); #tempN2= np.vstack(dictn2)
        np.savetxt(datFile_1,tempN1,delimiter=',',fmt='%s')
    return 

def removefiles(mode,path=None):
    os.chdir(path)
    files = os.listdir()
    if mode==1: ## mode can be zero or one 
        for file in files:
            os.remove(file)
    else:
        for file in files:
            if file.endswith(".lck"):
                os.remove(file)
# def no_memory():
#     virtual_memory = psutil.virtual_memory()
#     available_memory = virtual_memory.available
#     if available_memory/1000000 < 20000:
#         val = True
#     else:val = False
#     return val

### File read
def fileReader(filePath,cpPath=None):
    dataFile = open(filePath,"r")
    lines = dataFile.readlines()
    dataFile.close()
    if cpPath!=None:
        newmsgfile = open(cpPath,"w")
        for line in lines:
            newmsgfile.writelines(line)
    return lines

## Check solution has finished
def isCompleted(staFile,tConst):
    val = False;Tcmd = False
    try: # This is the default case that I always want it to check.
        if fileReader(staFile)[-1] == " THE ANALYSIS HAS COMPLETED SUCCESSFULLY\n":
            val = True; Tcmd = False
        elif fileReader(staFile)[-1] ==" THE ANALYSIS HAS NOT BEEN COMPLETED\n":
            val = True; Tcmd = False
        elif tConst>=120:
            val = True; Tcmd = True
        else: val = False; Tcmd = False
    except: # This case occurs when the .sta file is not yet written.
            val = False; Tcmd = False
    return val,Tcmd

# def ManageQueue(Process,Mcount,check):
#     if Mcount==1:
#         write2File(queFile,Mcount)
#         process_queue.put(Process)
#         check = False
#     else:
#         if int(fileReader(queFile)[-1])+1==Mcount:
#             write2File(queFile,Mcount)
#             process_queue.put(Process)
#             check = False
#     return process_queue,check

### Write to .mat file
# def write2matlab(dat,workspacePath):
#     mdic = {"dat": dat, "label": "experiment"}
#     output = os.path.join(MatlabOutput,"output_%s.mat"%(workspacePath.split("_")[-1]))
#     savemat(output, mdic)  
#     return 

### Display
def display(data):
    outputName2 = os.path.join(basePath,"debugReport.ascii")
    with open(outputName2,"a") as file:
        if type(data)==list:
            for ind,item in enumerate(data):
                cm = str(ind) + " %s\n"%item
                file.writelines(cm)
        else:
            file.writelines(data)

## Build working directory path and variable for matlab
def communicate():
    # key =True; count=0
    # while key:
    #     count+=1
    count = str(time.time()).split('.')[1] + str(random.randint(0,10000))
    workspacePath = os.path.join(RunDir,"workspace_%s"%(count))#inp3
    if not os.path.isdir(workspacePath):
        os.mkdir(workspacePath)
    return workspacePath,count

## The aim of this function is to check and ensure everything is in order before starting the optimisation
# This includes deleting workspace_%d folders, clearing out WorkQueue.ascii file.
# def initialise():
#     workspacePaths = glob.glob(os.path.join(RunDir,"workspace_*"))#inp3
#     output = glob.glob(os.path.join(MatlabOutput,"output_*.mat"))
#     queFile = [os.path.join(basePath,"WorkQueue.ascii")]
#     debugFile = [os.path.join(basePath,"debugReport.ascii")]
#     OdbqueFile = os.path.join(basePath,"OdbQueue.ascii")
#     files2delete = workspacePaths + output + queFile + debugFile
#     kill_proc('SMA')
#     for path in files2delete:
#         if os.path.isdir(path):
#             shutil.rmtree(path)
#         elif os.path.isfile(path):
#             os.remove(path)
#         else:
#             pass
#     return

# def kill_proc(jobName):
#     processes = psutil.process_iter()
#     for process in processes:
#         try:
#             tmp=process.cmdline()
#             if jobName in tmp:
#                 if jobName =="SMA": # This is to ensure that the process that is closed is the right one.
#                     results = messagebox.askyesno("Confirm process termination", f"Are you sure you want to terminate {process.name()}?")
#                     if results:
#                         process.terminate()
#                 process.terminate() # This is the default case if the item is in tmp
#         except:
#             continue

def OdbQueue(command):
    with open(OdbqueFile,"+a") as jobFile:
        jobFile.writelines(command+"\n")
    return

def findParameters(Directory):
    path = os.path.join(Directory,"TestJob-2.inp")
    path = path.replace('\temp',"\\temp")
    lines = fileReader(path)
    for ind,item in enumerate(lines):
        if item.startswith('*Material') and item.endswith('PM_MENISCAL_MEN\n'):
            coef = lines[ind+2].strip("\n")
            break
    return coef