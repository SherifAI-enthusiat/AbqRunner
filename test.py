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
# import HelperFunc as Hp
# import numpy as np
# import subprocess,os,shutil
# import glob
# cwdir = os.path.dirname(__file__)
# # expData = np.genfromtxt("compData.txt")

# def ReadWriteOdb(filePath):
#     paths = Hp.definePaths(filePath)
#     if os.path.exists(paths[0]):
#         shutil.rmtree(os.path.dirname(paths[0]))
#     dataRet = os.path.join(os.getcwd(),"readOdb.py")
#     command = 'abaqus python "%s"'%dataRet
#     commandn = r'%s -- "%s"'%(command,filePath)
#     pcall = subprocess.call(commandn,shell=True)
#     return

# def findParameters(lines):
#     for ind,item in enumerate(lines):
#         if item.startswith('*Material') and item.endswith('PM_MENISCAL_MEN\n'):
#             coef = lines[ind+2].strip("\n")
#             break
#     return coef

# Directory = "E:\Optimisation - Thesis studies\Knee 5"
# findFiles = glob.glob(Directory + "\Validation\workspace_*\*.inp")
# tmp = []
# for ind,val in enumerate(findFiles):
#     lines = Hp.fileReader(val)
#     tmp.append(findParameters(lines))
#     # To write results files
#     val = os.path.dirname(val)# val.strip("\\*.inp")
#     # newVal = glob.glob(val + "genOdb*.odb")
#     # newVal1 = glob.glob(val + "PCKnee*.odb")
#     ReadWriteOdb(val)
# tmp = np.vstack(tmp)
# np.savetxt("compData.txt",tmp,delimiter=',')

##############################################################
# import HelperFunc as Hp
# import os
# # import write2InpFile as w2p
# cwdir = "E:\\UOL_Knee 4\\Knee 4" 
# # cwdir = os.path.join(cwdir,"TestJob-2.inp")
# # Hp.findParameters(cwdir)
# test = Hp.findFiles(cwdir)
# test
# # x =[0.01, 0.01, 1.0, 0.01, 0.01, 0.01, 8.6, 18.4, 18.4]
# # orifile = "TestJob-2.inp"
# # workspacePath = "MatlabOutput"
# # w2p.writeInp(x,orifile,workspacePath,orifile)

import numpy as np
# Original coordinates
points_A = np.array([[46.586999999999996, 79.696, 37.504],
                     [34.867, 82.333, 38.969]])

# Target coordinates
points_B = np.array([[54.75, 84.3, 43.05],
                     [43.5, 87.7, 44.4]])

# Step 1: Calculate the centroids of both sets
centroid_A = np.mean(points_A, axis=0)
centroid_B = np.mean(points_B, axis=0)

# Step 2: Center the points around their respective centroids
centered_A = points_A - centroid_A
centered_B = points_B - centroid_B

# Step 3: Compute the covariance matrix
H = np.dot(centered_A.T, centered_B)

# Step 4: Use SVD to find the rotation matrix
U, S, Vt = np.linalg.svd(H)
R = np.dot(Vt.T, U.T)

# Step 5: Ensure the rotation matrix is proper (det(R) = 1)
if np.linalg.det(R) < 0:
    Vt[-1, :] *= -1
    R = np.dot(Vt.T, U.T)

# Step 6: Calculate the translation vector
t = centroid_B - np.dot(R, centroid_A)

# Output the rotation matrix and translation vector
print("Rotation Matrix (R):\n", R)
print("Translation Vector (t):\n", t)

# Apply the transformation to the original points for verification
testPoint = np.array([[46.586999999999996, 79.696, 37.504],
                     [34.867, 82.333, 38.969],
            [47.172999999999995,79.11,39.262 ],
[35.745999999999995,81.747,41.312999999999995],
            [46.879999999999995,80.868,39.555],
            [35.16,83.505,41.312999999999995],
            [46.879999999999995,81.161,40.141],
            [35.745999999999995,83.798,42.192]])
transformed_A = np.dot(testPoint, R.T) + t
print("Transformed Coordinates:\n", transformed_A)
print("Target Coordinates:\n", points_B)

