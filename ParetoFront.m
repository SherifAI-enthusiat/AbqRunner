%% Determining the distribution of menisci tissue property coefficient.
% This code will be used to determine the distribution of the material property parameters of the menisci
clear,clc,close all
kneeName = "Knee 5";
Obj = myFunctions().collectkneeDetails(kneeName);
basePath = "E:\\Optimisation - Thesis studies\\%s"; % E:\Optimisation - Thesis studies\Knee 5
path = sprintf(basePath,kneeName);
% path = fullfile(path,"workspace");
folders = Obj.findFiles(path);
folders = string(folders);
load(fullfile(Obj.path,"expData.mat"));
ba = size(folders,2); 
ab = 0; Kconst = 10;
controlWeights = zeros(4,12); % Pause in the debugger to define this value.
dataN =  repmat(struct('store', [] ,'data', []),Kconst,1);
for K=0:1:Kconst
    store = cell(1, ba);
    data =  repmat(struct('dat', [], 'tibiaF', [],'Obj', []), ba, 1);
    if ~isempty(dataN(1).data)
        const = dataN(1).data;
    end
    parfor i = 1:ba  %% Change to parfor
        Obj = myFunctions().collectkneeDetails(kneeName);
        Obj = Obj.optimisationControl(controlWeights);
        workspacePath = folders(1,i);
        if K==0 % This is only run in the first step to obtain the data.
            try
                [FE_dat,FE_tibiaF,Obj] = Obj.measureMenisci(workspacePath);
                Obj = Obj.resetData2Store();
                data(i).FE_dat = FE_dat; data(i).FE_tibiaF = tibiaF; data(i).Obj = Obj;
                dataCell = {FE_dat,Obj.expData,FE_tibiaF,Obj.tibiaFeatures,Obj.avgheight,Obj.axes(1),Obj.weights,Obj.K_value};
            catch Error
                dat = zeros(4,12);  tibiaF = zeros(8,3);
                data(i).dat = FE_dat; data(i).FE_tibiaF =FE_tibiaF;data(i).Obj = Obj;
                dataCell = {FE_dat,Obj.expData,FE_tibiaF,Obj.tibiaFeatures,Obj.avgheight,Obj.axes(1),Obj.weights,Obj.K_value};
            end
        else % for any other steps, data that was stored in the first step is used to calc the residuals.
            FE_dat = const(i).FE_dat; FE_tibiaF = const(i).FE_tibiaF;
            Obj= const(i).Obj; %defn = [Obj.mVal_lVal,Obj.axes(1)];
            dataCell = {FE_dat,Obj.expData,FE_tibiaF,Obj.tibiaFeatures,Obj.avgheight,Obj.axes(1),Obj.weights,Obj.K_value};
        end
        % tibialFeatures = obj.tibiaFeatures;
        [Res_Tot,Res_Men] = Obj.errorfunc(dataCell);
        params = Obj.findParameters(workspacePath);
        stn = params + ','+string(Res_Tot) +','+string(Res_Men);
        % stn = string(i) + ','+string(Residual);
        store(i) = {string(stn)};
    end
    ab = ab + 1;
    dataN(ab).store = store;
    dataN(ab).data = data;
end
%% Pareto plot
a = size(store,2);
tmp = zeros(a,10);
Kdata = zeros(ab,11);
for j = 1:ab
    for i = 1:a
        strn = dataN(j).store(i);
        tmp(i,:) = str2num(strn{1});
    end
    [~,mnind] = min(tmp(:,9));
    Kdata(j,:) = [j,tmp(mnind,:)];
end
figure(1)
scatter(Kdata(:,1),Kdata(:,end-1),"k*")
hold on
scatter(Kdata(:,1),Kdata(:,end),"ro")
xlabel("K value")
ylabel("Residual")
nam = strrep(kneeName, ' ', '')+"_HPC_obj_K.mat";
savePath = fullfile(Obj.path,nam);
save(savePath)
% % % Error function
% % function result = errorfuncA(data)
% %     trans_Tibia = [data{5}(1).*ones(4,3);data{5}(2).*ones(4,3)]; % Used to translate only along tibia loading axis
% %     tibialFeatures = data{4}+trans_Tibia; % This is meant to be a correction for the tibial movements - due to FE modelling. 
% % 	tempA = 100*(data{1}-data{2})./data{2}; % .*scalarM TO DO need to check dimensions here.
% %     tempA = data{7}.*tempA; % Used to control situations when meaurement is problematic
% %     tempB = 100*(data{3}-tibialFeatures)./tibialFeatures;		
% % 	tempB = data{8}.*tempB(:,data{6}); % This should be a single dimension - Verify
% % 	temp1 = sum(tempA.^2,'all');
% %     temp2 = sum(tempB.^2,'all'); % To check -----
% %     result = temp1 + temp2; % Up
% % end