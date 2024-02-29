## Post processing
# from inspect import Parameter
import sys
import os

# Processing parameters 
tem = sys.argv[10:][0:]
ntem = tem[0:]
#writeError(ntem,cwd)
ftem =[]
for item in ntem:
    if item.startswith("["):
        nter = (item.strip("["))
        ftem.append(nter.strip(","))
    elif item.endswith("]"):
        ftem.append(item.strip("]"))
    elif item == "'":
        pass
    else:
        ftem.append(item.strip(" ,"))

parameter = tuple(ftem)
temp_path = sys.argv[-10] ## Previous sys.argv[-10]
fileName = sys.argv[-11]+".odb"
Root_cwd ='/nobackup/mnsaz/Mengoni_tool'# For HPC
wks_folder = os.path.join(Root_cwd,temp_path)
# Root_cwd ='C:\WorkThings\github\Mengoni_tool'# For My PC
odbToolbox = os.path.join(Root_cwd,"postProTools") # Paths to .odb tool required
contactTool = os.path.join(Root_cwd,"Test") # Path to contact tool
odbname = os.path.join(wks_folder,"%s"%fileName)
sys.path.append(odbToolbox)
sys.path.append(contactTool)
import tools.odbTools as odbTools
import tools.extractors as ext
import numpy as np
import OdbTool_1_ver1 as AnOdb_tool

## Contact area 
myOdb = odbTools.openOdb(odbname)
defn = AnOdb_tool.definitions(myOdb)# Defintions in dictionary
medCP,latCP = AnOdb_tool.answers(defn) # medCP & latCP variables

## femur-tibia displacement
displExt = ext.getU_Magnitude(myOdb,"COMBINED")
displ = displExt[-1] # displExt contains two lists which denote the two frames or steps but we are interested in the last one
displC1 = ext.getNCoord(myOdb,"COMBINED") # SMZ-->(14/12/2021) Two nodes 1 on femur and 1 on tibia.
array = np.array([]).reshape(0,3)
for item in displC1:
    array = np.vstack((array,item))
diff = np.linalg.norm(array[0,:]-array[1,:])
disp = diff-(displ[0]+displ[1]) # the femur and tibia are beng squished hence
dispn = [disp]
# tot = MedCP+LatCP
# odbTools.writeValuesOpti(zip(medCP,latCP,disp))
# File update 
import csv
csvfile = sys.argv[-11]+'.csv'
filename = os.path.join(Root_cwd,"%s"%csvfile) # Results file for displacements of nodes
myfile = os.path.isfile(filename)
new_par = [item for item in parameter]
field_names = ['Parameters', 'MedCP', 'LatCP','Displacement-FT'] 
compiled = {'Parameters': new_par, 'MedCP': medCP, 'LatCP': latCP ,'Displacement-FT':dispn}
k=0
with open(filename,'a') as file:
    if not myfile:
        writer = csv.DictWriter(file,fieldnames=field_names)
    while k==0:
        try:
            writer = csv.DictWriter(file,fieldnames=field_names).writerow(compiled)
            k=1
        except:
            k=0
myOdb.close()
