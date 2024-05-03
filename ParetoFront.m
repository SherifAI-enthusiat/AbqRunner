%% Determining the distribution of menisci tissue property coefficient.
% This code will be used to determine the distribution of the material property parameters of the menisci
clear,clc,close all
kneeName = "Knee 2";
Obj = myFunctions().collectkneeDetails(kneeName);
basePath = "E:\\Optimisation - Thesis studies\\%s";
path = sprintf(basePath,kneeName);
% path = fullfile(path,"workspace");
folders = Obj.findFiles(path);
folders = string(folders);
load(fullfile(Obj.path,"expData.mat"));
ba = size(folders,2); ab = 0; Kconst = 26;
dataN =  repmat(struct('store', [] ,'data', []),Kconst,1);
for K=0:1:Kconst
    store = cell(1, ba);
    data =  repmat(struct('dat', [], 'tibiaF', [],'Obj', []), ba, 1);
    if ~isempty(dataN(1).data)
        const = dataN(1).data;
    end
    parfor i = 1:ba
        Obj = myFunctions().collectkneeDetails(kneeName);
        workspacePath = folders(1,i);
        if K==0 % This is only run in the first step to obtain the data.
            try
                [dat,tibiaF,Obj] = Obj.measureMenisci(workspacePath);
                Obj = Obj.resetData2Store();
                data(i).dat = dat; data(i).tibiaF = tibiaF; data(i).Obj = Obj;
                defn = [Obj.mVal_lVal,Obj.axes(1)]; 
            catch Error
                dat = zeros(4,12);  tibiaF = zeros(8,3);
                data(i).dat = dat; data(i).tibiaF =tibiaF;
                defn = [[0,0],Obj.axes(1)]; Obj.mVal_lVal = [0,0];
                data(i).Obj = Obj;
                % disp(Error)
            end
        else % for any other steps, data that was stored in the first step is used to calc the residuals.
            dat = const(i).dat; tibiaF = const(i).tibiaF;
            Obj= const(i).Obj; defn = [Obj.mVal_lVal,Obj.axes(1)];
        end
        % tibialFeatures = obj.tibiaFeatures;
        Residual = errorfuncA(defn,dat,tibiaF,expData,tibiaFeatures,K);
        params = Obj.findParameters(workspacePath);
        stn = params + ','+string(Residual);
        % stn = string(i) + ','+string(Residual);
        store(i) = {string(stn)};
    end
    ab = ab + 1;
    dataN(ab).store = store;
    dataN(ab).data = data;
end
%% Pareto plot
a = size(store,2);
tmp = zeros(a,9);
Kdata = zeros(ab,10);
for j = 1:ab
    for i = 1:a
        strn = dataN(j).store(i);
        tmp(i,:) = str2num(strn{1});
    end
    [~,mnind] = min(tmp(:,9));
    Kdata(j,:) = [j,tmp(mnind,:)];
end
figure(1)
scatter(Kdata(:,1),Kdata(:,10),"k*")
xlabel("K value")
ylabel("Residual")
nam = strrep(kneeName, ' ', '')+"_HPC_obj_K.mat";
savePath = fullfile(Obj.path,nam);
save(savePath)
%% Error function
function result = errorfuncA(defn,data,data1,expData,tibialFeatures,K)
    tempA = 100*(data-expData)./expData; % .*scalarM TO DO need to check dimensions here.
    dataK = vertcat(defn(1)*ones(4,1),defn(2)*ones(4,1));
    data1(:,3) = data1(:,defn(3))+dataK; % this is to correct for the femur movement in the assembly
    tempB = 100*(data1-tibialFeatures)./tibialFeatures;
    temp1 = sum(tempA.^2,'all');
    temp2 = sum(tempB.^2,'all');
    result = temp1 + K.*temp2; 
end