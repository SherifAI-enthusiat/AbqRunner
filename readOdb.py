# # import pickle as pk
# # import numpy as np
# # import os

# # workspacePath = "RunDir/workspace_1"
# # outputName = os.path.join(workspacePath,"feaResults.ascii")
# # if os.path.exists(outputName):
# #     dat= np.genfromtxt(outputName, delimiter=",")

# # # tmp=pk.dumps(dat)
# # path = workspacePath+"/data.npy"
# # np.save(path,dat)

# # # data = pk.loads(tmp)
# # # print(data)

# # modelName = 'YourModel'
# from odbAccess import openOdb
# loadStepName = 'Load1'
# SetName = "PCKNEE2_MENISCI-1.MEDSURF"
# odbPath = 'C:\Temp\Job-3-v1-Copy-v5.odb'
# tmp =[]; tmp1 = []
# myOdb = openOdb(odbPath)
# frame_data = myOdb.steps[loadStepName].frames[-1]
# test = frame_data.fieldOutputs['U']
# # loadStep = myOdb.steps[loadStepName]
# # u = myOdb.steps[loadStepName].frames[-1].fieldOutputs['U']
# # test = myOdb.rootAssembly.instances.nodeSets[deformedSet].coordinates
# # ## Test 
# # for it in range(len(u)):
# #     tmp.append(u.values[it].data) ## array of (ux,uy,uz)
# #     ndl = u.values[it].nodeLabel  ## node label
# #     data = myOdb.rootAssembly.instances.getNodeFromLabel(ndl).coordinates
# #     tmp1.append(data)
        
# from abaqusConstants import NODAL,COMPONENT
# COORD1_Fr = session.xyDataListFromField(odb=myOdb,outputPosition=NODAL,variable=(('COORD', NODAL, ((COMPONENT, 'COOR1'),)),),nodeSets=(SetName,),steps=(loadStepName, "LAST"))


# myOdb.close()
# print(COORD1_Fr[0][1][1])



import sys,os
from odbAccess import NODAL
import numpy as np
import glob
# from pathlib import Path
absPath = os.getcwd()
workspacePath = sys.argv[-1]
### Display
def display(data):
    outputName2 = os.path.join(absPath,"debugReport.ascii")
    with open(outputName2,"a") as file:
        if type(data)==list:
            for ind,item in enumerate(data):
                cm = str(ind) + " %s\n"%item
                file.writelines(cm)
        else:
            file.writelines(data)

def displacementData(datHandle):
    temp = []
    for ind in range(len(datHandle.values)):
        dat = datHandle.values[ind].data
        temp.append(dat)
    return temp

def undeformedCoordData(nodeset,dataPath):
    temp = []
    for ind in range(len(nodeset.nodes[0])):
        point = nodeset.nodes[0][ind].coordinates
        temp.append(point)
    data = np.vstack(temp)
    np.savetxt(dataPath,data,delimiter=',')
    return 

def saveData2File(filePath,tmp,append=False):
    if append ==True:
        data = np.vstack((tmp[0][0],tmp[1][0],tmp[2][0],tmp[3][0]))
        with open(filePath,'a') as filePath:
            np.savetxt(filePath,data,delimiter=',')
    else:
        data = np.vstack((tmp[0],tmp[1],tmp[2],tmp[3]))
        np.savetxt(filePath,data,delimiter=',')
    return

def getnodeSet(myOdb,surf):
    for set in myOdb.rootAssembly.nodeSets.keys():
        if set.endswith(surf): # This is either "MEDDisplData" and "LATDisplData"
            subset = myOdb.rootAssembly.nodeSets[set]
            newset = set
    return subset, newset

def RetrieveData(workspacePath):
    workspacePath = workspacePath.strip('"')
    odbToolbox = os.path.join(absPath,"postProTools")
    medCoordPath = os.path.join(workspacePath,"Results\medCoordData.txt")
    latCoordPath = os.path.join(workspacePath,"Results\latCoordData.txt")
    medEpiCoordPath = os.path.join(workspacePath,"Results\medEpiCoordData.txt")
    latEpiCoordPath = os.path.join(workspacePath,"Results\latEpiCoordData.txt")
    medDisplPath = os.path.join(workspacePath,"Results\medDisplData.txt")
    latDisplPath = os.path.join(workspacePath,"Results\latDisplData.txt")
    # odbFile = os.path.join(workspacePath,"genOdb_%s.odb"%(workspacePath.split("_")[-1]))
    # display(medEpiCoordPath+'\n')
    if os.path.isfile(os.path.join(workspacePath,"PCKnee.odb")):
        odbFile = os.path.join(workspacePath,"PCKnee.odb")
    else:
        stn = workspacePath + "\genOdb*.odb"
        odbFile = glob.glob(stn)
        odbFile = odbFile[0]
    os.mkdir(os.path.dirname(latEpiCoordPath)) # Creates the Results path for my files
    # odbFile = "C:\Temp\knee4_test-v3.odb" # Allows me to test tibia features.
    sys.path.append(odbToolbox)
    # sys.path.append(ContactTool)
    import tools.odbTools as odbTools
    import tools.extractors as ext
    # import OdbTool_1_ver1 as AnOdb_tool
    myOdb = odbTools.openOdb(odbFile)
    
    menSurf =['MEDSURF','LATSURF','LATEPICONDYLE','MEDEPICONDYLE']
    menNew = ['MEDEPICONDYLE','LATEPICONDYLE']
    # Undeformed Coordinates to file - Check to see of the file exists first before writing
    # if not os.path.isfile(medCoordPath):
    for itm in menSurf:
        subsetHandle,set = getnodeSet(myOdb,itm)
        if set.endswith('MEDSURF'):
            undeformedCoordData(subsetHandle,medCoordPath)
        elif set.endswith('LATSURF'):
            undeformedCoordData(subsetHandle,latCoordPath)
    for itm in menNew: 
        subsetHandle,set = getnodeSet(myOdb,itm)
        if set.endswith('MEDEPICONDYLE'):
            undeformedCoordData(subsetHandle,medEpiCoordPath)
        else:
            undeformedCoordData(subsetHandle,latEpiCoordPath)

    tmp_med = []; tmp_lat =[]; tmp_epi_med =[];tmp_epi_lat =[]
    for _,stpName in enumerate(myOdb.steps.keys()):
        if stpName.startswith('Load') or stpName.startswith('Move'):
            try:
                frameData = myOdb.steps[stpName].frames[-1]
                fieldData = frameData.fieldOutputs['U']
                for itm in menSurf:
                    subsetHandle,surf = getnodeSet(myOdb,itm)
                    if surf.endswith('MEDSURF'):
                        dat = fieldData.getSubset(region=subsetHandle,position=NODAL)
                        newdat = displacementData(dat)
                        tmp_med.append(newdat)
                    elif surf.endswith('LATSURF'):
                        dat = fieldData.getSubset(region=subsetHandle,position=NODAL)
                        newdat = displacementData(dat)
                        tmp_lat.append(newdat)
                    elif surf.endswith('MEDEPICONDYLE'):
                        dat = fieldData.getSubset(region=subsetHandle,position=NODAL)
                        newdat = displacementData(dat)
                        tmp_epi_med.append(newdat)
                    elif surf.endswith('LATEPICONDYLE'):
                        dat = fieldData.getSubset(region=subsetHandle,position=NODAL)
                        newdat = displacementData(dat)
                        tmp_epi_lat.append(newdat)
            except:
                continue

    saveData2File(medDisplPath,tmp_med)
    saveData2File(latDisplPath,tmp_lat)
    saveData2File(medEpiCoordPath,tmp_epi_med,append=True)
    saveData2File(latEpiCoordPath,tmp_epi_lat,append=True)

    myOdb.close()
    return 

# display("Before - Retrieve data function"+'\n')
RetrieveData(workspacePath)