import os
import sys
import math
#from Display import writeError
cwd = "/nobackup/mnsaz/Mengoni_tool/"

# Processing parameters 
tem = sys.argv[3:][0:]
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
#writeError(ftem,cwd)

# Path
fileName = sys.argv[1]+".inp"
filePath = os.path.join(cwd,'RunDir/%s'%fileName)
temp = 'workspace/temp-%s/%s'%(sys.argv[2],fileName)
#writeError(temp,cwd)
filePath2 = os.path.join(cwd,temp)
with open(filePath, 'r') as oldlines:
    lines = oldlines.readlines()

# Material property change with regards to menisci and attachement site
data ={}
data["spring_locs"] = []
data['menisci_locs'] = []
test2 = tuple(float("{:.2f}".format(float(item))) for item in ftem)
new_param = str(test2[0])
for ind,item in enumerate(test2):
    if ind!= 0 and ind <=7:
        new_param = new_param + ', %s'%item
for ind,item in enumerate(lines):
    if item.startswith('*Spring'):
        temp3 = '%s\n'%float("{:.2f}".format(test2[2]/15))
        data['spring_locs'].append(ind+2)
    elif item.startswith('*Material') and item.endswith('_MEN\n'):
        data['menisci_locs'].append(ind+2)

# Writing to new .INP file
data['combined'] = data['spring_locs']+data['menisci_locs']
with open(filePath2,"w") as file2write:
    for ind,item in enumerate(lines):
        if ind in data['combined']:
            if ind in data['menisci_locs']:
                if ind== max(data['menisci_locs']):
                    file2write.writelines(new_param +'\n')
            elif ind in data['spring_locs']:
                file2write.writelines(temp3)
        elif ind == max(data['menisci_locs'])+1:
            file2write.writelines(' '+ str(test2[-1]) +',\n')
        else:
            file2write.writelines(item)
