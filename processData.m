%% Determining the distribution of menisci tissue property coefficient.
% This code will be used to determine the distribution of the material property parameters of the menisci
Obj = myFunctions().collectkneeDetails("Knee 2");
dat = Obj.findFiles();
store = {};
for i = 1:size(dat,2)
    workspacePath = string(dat(1,i));
    try
        [data,Obj] = Obj.measureMenisci(workspacePath);
    catch
        data = zeros(4,12);
    end
    Residual = Obj.errorfunc(data);
    params = Obj.findParameters(workspacePath);
    stn = params + ','+string(Residual);
    store(i) = {string(stn)};
    
end

%% Read results and calculate residual
load("knee5_HPC.mat")
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
bol = tmp(:,9)<=25000;
rmTmp = tmp(bol,:);
figure(3)
scatter3(rmTmp(:,1),rmTmp(:,3),rmTmp(:,9))
xlabel("Axial stiffness")
ylabel("Circumferential stiffness")
zlabel("Residual")

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
%% Coordinate system check
% Center the data points by subtracting the mean of each coordinate
points_global = [4.396, -6.235, 10.181;	
-29.093, -12.835, 9.922;
-0.8771, -29.179, 10.778;	
-19.585, -40.418, 10.805];
points_other = [63.184, 3.307, 43.86;
29.097, 2.189, 42.466;
54.444, 3.803, 21.998;	
34.236, 3.458, 13.76];


