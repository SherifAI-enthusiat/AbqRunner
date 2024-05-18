%% Determining the distribution of menisci tissue property coefficient.
% This code will be used to determine the distribution of the material property parameters of the menisci
clear,clc
Obj = myFunctions().collectkneeDetails("Knee 4");
folders = Obj.findFiles("E:\Optimisation - Thesis studies\Knee 4");
folders = string(folders);
load(fullfile(Obj.path,"expData.mat"));
store = {}; ba = size(folders,2); 
for i = 1:ba
    Obj = myFunctions().collectkneeDetails("Knee 4");
    workspacePath = folders(1,i);
        try
            [dat,tibiaF,Obj] = Obj.measureMenisci(workspacePath);
        catch Error
            dat = zeros(4,12);  tibiaF = zeros(8,3);
            disp(Error)
        end
    % tibialFeatures = obj.tibiaFeatures;
    Residual = errorfuncA(dat,tibiaF,expData,tibiaFeatures);
    params = Obj.findParameters(workspacePath);
    stn = params + ','+string(Residual);
    % stn = string(i) + ','+string(Residual);
    store(i) = {string(stn)};
    
end

%% Read results and calculate residual
% strc = 'MatlabOutput\Knee 4\knee4_HPC_obj.mat';%% This is where I can change bits.
% load(strc)
a = size(store,2);
tmp = zeros(a,9);
for i = 1:a
    strn = store(i);
    tmp(i,:) = str2num(strn{1});
end


figure(1)
scatter(tmp(:,1),tmp(:,3),"k*")
xlabel("Axial stiffness")
ylabel("Circumferential stiffness")
figure(2)
scatter3(tmp(:,1),tmp(:,3),tmp(:,9))
xlabel("Axial stiffness")
ylabel("Circumferential stiffness")
zlabel("Residual")
%% Filter resifual
bol = tmp(:,9)<=50000000;
rmTmp = tmp(bol,:);
[~,mnind] = min(tmp(:,9));
[~,mxind] = max(rmTmp(:,9));
minVal = tmp(mnind,:);
maxVal = rmTmp(mxind,:);
figure(3)
scatter3(rmTmp(:,1),rmTmp(:,3),rmTmp(:,9))
hold on
scatter3(minVal(:,1),minVal(:,3),minVal(:,9))
xlabel("Axial stiffness")
ylabel("Circumferential stiffness")
zlabel("Residual")
hold off
figure(4)
scatter(rmTmp(:,3),rmTmp(:,9))
% hold on
% scatter(minVal(:,3),minVal(:,9))
xlabel("Circumferential stiffness")
ylabel("Residual")
hold off

%% Plot of residual
X = data(:,1); Y = data(:,3); Z = data(:,9);
tmp= ones(size(Z,1),1)*4.402850;
Zn = (tmp - Z).^2;
var = fit([X,Y],Zn,"poly23");
plot(var)
colorbar
hold on
plot3(X,Y,Z,'b*')
xlabel("Eplane"); ylabel("Efibre"); zlabel("Sqd. residual")
hold off
%% To determine the Coordinates
close all
undeformed = [60.063, 40.807, 31.287;9.685, 20.804, 47.485;66.813, 24.645, 58.331];
deformed = [63.033, 25.476, 30.712;68.842, 33.425, 61.518;12.827, 19.441, 55.804];
% fe_undeformed = [50.710751,3.947016,16.539185;35.973877,3.482223,14.582053;...
% 56.378788,3.227519,39.750175;29.160379,2.282356,40.198074];
% fe_deformed = [65.059402,7.637124,66.590736;65.41024,1.506655,59.788509;...
% 32.29631,6.610365,68.396652;34.646263,5.587093,59.97123];
und = mean(undeformed);
def = mean(deformed);

% % Generate point cloud
pcUnd = pointCloud(undeformed);
pcDef = pointCloud(deformed);
% pcFeUnd = pointCloud(fe_undeformed);
% pcFeDef = pointCloud(fe_deformed);
% Determine plane information
err = .35;
UndplnData = pcfitplane(pcUnd,err);
DefplnData = pcfitplane(pcDef,err);
% FeUndplnData = pcfitplane(pcFeUnd,err);
% FeDefplnData = pcfitplane(pcFeDef,err);
% Plot data
scatter3(undeformed(:,1),undeformed(:,2),undeformed(:,3),"k*")
hold on
scatter3(deformed(:,1),deformed(:,2),deformed(:,3),"r*")
plot(UndplnData,"Color","blue")
plot(DefplnData,"Color","green")
% plot(FeUndplnData,"Color","cyan")
% plot(FeDefplnData,"Color","cyan")
% scatter3(poi_line(:,1),poi_line(:,2),poi_line(:,3),"cs")
% legend("Undeformed coords","Deformed coords","Undeformed plane","Deformed plane","FE mesh")
legend("Undeformed coords","Deformed coords","Undeformed plane","Deformed plane")
xlabel("X -axis");ylabel("Y -axis");zlabel("Z -axis")
% Determines the normal of the intersection
n1 = UndplnData.Normal; n2 = DefplnData.Normal;
ndorm = cross(n1,n2);
cos_theta = dot(n1, n2) / (norm(n1) * norm(n2));
theta = acos(cos_theta)*180/pi;  
%% Determine point of intersection
a1 = [a1_1.Position;a1_2.Position]; 
b1 = [b1_1.Position;b1_2.Position];  % These are determined graphically
dirV_a1 = a1(1,:) - a1(2,:);
dirV_b1 = b1(1,:) - b1(2,:);
syms t0 t1
f1 = a1(1,:) + t0*dirV_a1;
f2 = b1(1,:) + t1*dirV_b1;
poi_int = solve(f1==f2,t0,t1);
f1 = a1(1,:) + eval(poi_int.t0)*dirV_a1;
f2 = b1(1,:) + eval(poi_int.t1)*dirV_b1;
poi_line2 = f1 + 10*ndorm;
poi_line = [f1;poi_line2];
scatter3(poi_line(:,1),poi_line(:,2),poi_line(:,3),"rs")
hold off
%% Statistics
newPa = rmTmp(:,[1,3,8,9]);
objt = anova(newPa);
%% Error function defintions
function result = errorfuncA(data,data1,expData,tibialFeatures)
    tempA = 100*(data-expData)./expData; % .*scalarM TO DO need to check dimensions here.
    tempB = 100*(data1-tibialFeatures)./tibialFeatures;
    temp1 = sum(tempA.^2,'all');
    temp2 = sum(tempB.^2,'all');
    result = temp1 + 1000.*temp2; 
end

% store ={};
% for i=1:a
%      params = Obj.findParameters(folders(i));
%      Residual = tmp(i,2);
%      stn = params + ','+string(Residual);
%      store(i) = {string(stn)};
% end

