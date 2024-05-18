classdef myFunctions
    properties
        parameters; % these are parameters used to determine a cylinder.
        sfM; % this approx surface data.
        X_conv; % 
        oriCoords; % These are teh original coordinates collected from Abaqus - these are undeformed coordinates.
        med_men_length; % This is dimension length of the medial mesh from Matlab
        defCoords; % This is used to store the resultant coords for all load cases.
        revCentres; % These are the new tibial centres for measurement purposes.
        results; % Results of measured displacements.
        axes; % these are variables from ScanIP for making measurements in MATLAB.
        pixelConv; % This is data from ScanIP i.e. convertion factor from pixel to length(mm).
        path; % Path to experimental data stored.
        mnmx; % this is pretty much just for knee 5 - where SI points downwards.All the other cases are fine
        weights;
        expData;
        tibiaFeatures;
        avgheight; % this quantity is used to store some height value from Move step.
        mVal_lVal; % Used to adjust experimental tibial movement data in error function(Pareto front).
        error_Value = [];
        K_value = 0;
        testPath ;
        test = "False"
    end 

    methods
        %% Cost function for the optimissation - this function handles everything
        function [outputn] = myscript(obj,x)
        % This function evaluates in Abaqus and returns a variable "count" which is
        % used to locate the results file.
            vp = .01; vf_p = .01;
            Gp = x(1)/(2*(1+vp)); % Gp
            x = [x(1),x(1),x(2),vp,vf_p,vf_p,Gp,x(3),x(3)];
        %     scalarM = 100.*ones(size(expData));
            ff = fullfile(obj.path,{'expData.mat'});
            load(string(ff(1)));  
            if py.ParamTools.material_stability(x)
                formatSpec = 'lstestv2_parallel.py %d %d %d %d %d %d %d %d %d "%s"';%% This is where I can change bits.
                cmd = sprintf(formatSpec,x(1),x(2),x(3),x(4),x(5),x(6),x(7),x(8),x(9),obj.path); % 
                if obj.test == "True"
                    workspacePath = obj.testPath;
                else % This is the default
                    [~, workspacePath]= pyrunfile(cmd,["Mcount","workspacePath"]);
                end
                try
                    [FE_dat,FE_tibiaF,obj] = obj.measureMenisci(workspacePath);
					% data.dat = dat; data.tibiaF = tibiaF;
                    dataCell = {FE_dat,obj.expData,FE_tibiaF,obj.tibiaFeatures,obj.mVal_lVal,obj.axes(1),obj.weights,obj.K_value};
                catch
                    FE_dat = zeros(4,12); FE_tibiaF = zeros(8,3);
					% data.dat = dat; data.tibiaF = tibiaF;
                    dataCell = {FE_dat,obj.expData,FE_tibiaF,obj.tibiaFeatures,obj.mVal_lVal,obj.axes(1),obj.weights,obj.K_value};
                end
            else
				FE_dat = zeros(4,12); FE_tibiaF = zeros(8,3);
				% data.dat = dat; data.tibiaF = tibiaF;
                dataCell = {FE_dat,expData,FE_tibiaF,tibiaFeatures,[0,0],obj.axes(1),obj.weights,obj.K_value};
            end
            [outputn,menContribution] = obj.errorfunc(dataCell);
			resid = [menContribution,outputn]; % Menisci and tibial contributions
			obj.error_Value = vertcat(obj.error_Value,resid);
        end
        %% This function handles the secondary aspect of the optimisation
        function [measuredDisplacements,tibiaData,obj] = measureMenisci(obj,path)
            % This script collects the radial displacements of the menisci with respect two points at approx. centre of either tibial compartment.
            %% To - Do 
            % ------  Input required for optimisation
            % Need medial and lateral coordinate data - Done
            % Need medial and lateral displacement data - Done
            % Need tibial epicondyle location data - Done
            % Need axis data and location of derived - Done
            % Need path for finding results - Done
            % fig1 = figure(1); oriAx = axes;
            %% Undeformed and displacement data
            fp_coords = fullfile(obj.path,["medCoordData.txt";"latCoordData.txt";"expData.mat"]);
            fp_disp = fullfile(string(path)+"\Results",['medDisplData.txt';"latDisplData.txt";"medEpiCoordData.txt";"latEpiCoordData.txt"]);
            med_men = readmatrix(string(fp_coords(1)));lat_men = readmatrix(string(fp_coords(2)));
            med_men_displ = readmatrix(string(fp_disp(1)));lat_men_displ = readmatrix(string(fp_disp(2)));
            medEpiCoord = readmatrix(string(fp_disp(3)));latEpiCoord = readmatrix(string(fp_disp(4)));
            % Undeformed data - Move step is applied to bring it to the undeformed technically. 
            % Since Abaqus has issues with surfaces in contact. So i have to rearrange the data into four load steps and added the Move step load case to coord data.
            %% This piece of code determines the axis on which the menisci lies - {Doesnt work consistently for all samples hence I decided to ignore it}
            % Obj = myFunctions();
            load(string(fp_coords(3)));
            obj.expData = expData;
            obj.tibiaFeatures = tibiaFeatures;
            obj.oriCoords = vertcat(med_men,lat_men);
            obj.med_men_length = size(med_men,1); 
            displ = vertcat(med_men_displ,lat_men_displ);
            % axisSI= obj.determineSI_Dir(); % Determines the horizontal plane within the coordinates
            % axisAP = obj.determineAP_Dir(); % This is experimental - i need to check that it works for all cases.
            % axes = [axisSI,axisAP];
            %% This piece of code determines the location of the menisci points for measurements.
            tibiaEpiCoords = obj.calcTibiaFeatures(medEpiCoord,latEpiCoord);% Calcs coordinate data for tibial features for the different load states. 
            tibiaData = [tibiaEpiCoords.med;tibiaEpiCoords.lat];
            [Points2Measure,obj.revCentres] = obj.PointsAroundMenisci(tibiaEpiCoords,planeHeight,obj.axes,displ);
            %% I am here - Need to verify that points around the menisci are at the right location.
            % relative to surface from Abaqus. i then need to check resultant coords and measure points.
            %% FindPointsInCylinder function
            [measuredDisplacements,obj] = obj.EstimateMenisciDisplacements(Points2Measure,displ);
            %% Examine the output from processing.
            % figure(3)
            % hold on
            % for it=1:4
            %     step =[Obj.defCoords(it).med;Obj.defCoords(it).lat];
            %     scatter3(step(:,1),step(:,2),step(:,3));
            % end
        end
        %% Cost function for optimisation
        function [result,temp1] = errorfunc(obj,data)
            trans_Tibia = [data{5}(1).*ones(4,3);data{5}(2).*ones(4,3)]; % Used to translate only along tibia loading axis
            tibialFeatures = data{4}+trans_Tibia; % This is meant to be a correction for the tibial movements - due to FE modelling. 
			tempA = 100*(data{1}-data{2})./data{2}; % .*scalarM TO DO need to check dimensions here.
            tempA = data{7}.*tempA; % Used to control situations when meaurement is problematic
            tempB = 100*(data{3}-tibialFeatures)./tibialFeatures;		
			tempB = data{8}.*tempB(:,data{6}); % This should be a single dimension - Verify
			temp1 = sum(tempA.^2,'all');
            temp2 = sum(tempB.^2,'all'); % To check -----
            result = temp1 + temp2; % Updated objective function - includes the tibial motion into the menisci. Addresses the issue where the menisci is increasingly stiffening.
        end
        %% For storing variables
        function obj = variables(obj,parameters,sfM,varargin)
            if ~isempty(varargin)
                obj.X_conv = varargin{1};
            end
            obj.parameters = parameters;
            obj.sfM = sfM;
        end
        %% Generating point to build cylinder
        function symmetric_ang = generatePoints(obj,startAng, noPoints)
            interval_size = startAng * 2 / (noPoints - 1);
            symmetric_ang = zeros(1, noPoints);
            
            for it = 1:noPoints
                ang = startAng - interval_size * (it - 1);
                symmetric_ang(it) = ang;
            end
        end
        
        %% Rptation matrix to build cylinder
        function [rotMa] = rotationMat(obj,rot_deg,axis)
            rad = deg2rad(rot_deg);
            if axis== 1
                rotMa = [1, 0, 0;
                         0, cos(rad), -sin(rad);
                         0, sin(rad), cos(rad)];
            elseif axis== 2
                rotMa = [cos(rad), 0, sin(rad);
                         0, 1, 0;
                         -sin(rad), 0, cos(rad)];
            elseif axis== 3
                rotMa = [cos(rad), -sin(rad), 0;
                         sin(rad), cos(rad), 0;
                         0, 0, 1];
            end
        end

        %% Convert cylinder to Point cloud
         function [X, Y, Z] = transformCylinder(obj,this, X, Y, Z)
            a = cast([0, 0, 1], 'like', this.Parameters);
            h = this.Height;
            % Rescale the height.
            Z(2, :) = Z(2, :) * h;
            
            if h == 0
                b = [0, 0, 1];
            else
                b = (this.Parameters(4:6) - this.Parameters(1:3)) / h;
            end
            
            % Rotate the points to the desired axis direction and translate
            % the cylinder.
            translation = this.Parameters(1:3);
            if iscolumn(translation)
                translation = translation';
            end
            v = cross(a, b);
            s = dot(v, v);
            if abs(s) > eps(class(s))
                Vx = [ 0, -v(3), v(2); ...
                     v(3),  0,  -v(1); ...
                    -v(2), v(1),   0];
                R = transpose(eye(3) + Vx + Vx*Vx*(1-dot(a, b))/s);
                
                XYZ = bsxfun(@plus, [X(:), Y(:), Z(:)] * R, translation);
            else % No rotation is needed, only translation.
                XYZ = bsxfun(@plus, [X(:), Y(:), Z(:)], translation);
            end
            X = reshape(XYZ(:, 1), 2, []);
            Y = reshape(XYZ(:, 2), 2, []);
            Z = reshape(XYZ(:, 3), 2, []);
         end

        %% This works for interpolating and finding the point around the cylinder.
        % Generates a cylinder given bottom and top points of the cylinder and the
        % radius.Dimension [1*7]
    function [interData,cyl_model,obj] = cylinderIntersect(obj,parameters,testData) 
            % close all % This is important because I use the figure to obtain the point hence only figure here is kept.
            cyl_model = cylinderModel(parameters);
            [X, Y, Z] = cylinder(parameters(7), 100);
            [X, Y, Z] = obj.transformCylinder(cyl_model,X, Y, Z);
            % Separating into bottom and top circle making the cylinder.
            X1 = X(1,:); X2 = X(2,:); 
            Y1 = Y(1,:); Y2 = Y(2,:); 
            Z1 = Z(1,:); Z2 = Z(2,:); 
            D1 = [X1',Y1',Z1']; D2 = [X2',Y2',Z2']; % D1 is bottom cylinder and D2 is top cylinder 
            dirVec = D2 - D1; % This is the corresponding direction vectors between points.
            t = linspace(0,1,100); 
            % fig2 = openfig('InitialMenisci.fig');
            % set(0, 'CurrentFigure', fig2);
            newTable = [];
            % fig2 = figure(2); ax1 = axes; 
            % hold(ax1,"on") % If require we can assign axes and plot in specifc figure
            for i=1:size(D1,1)
                NewC = D1(i,:) + t'.*dirVec(i,:);
                newTable = [newTable,NewC'];
                % plot3(NewC(:,1),NewC(:,2),NewC(:,3),"ks")  % This plot is in essense used to store and retrieve data
            end 
            
            AxisD = parameters(1:3) + t'.*dirVec(1,:); % dirVec(i,:) any direction here is // to cyl axis
            newTable = [newTable,AxisD'];
            % plot3(ax1,AxisD(:,1),AxisD(:,2),AxisD(:,3),"rs")
            % hold(ax1,"off")
            % set(0, 'CurrentFigure', fig2); h = gcf;  %current figure handle
            % axesObjs = get(h, 'Children');  %axes handles
            % dataObjs = get(axesObjs, 'Children'); 
            % xdata = get(dataObjs, 'XData'); 
            % ydata = get(dataObjs, 'YData');
            % zdata = get(dataObjs, 'ZData');
            % cyl_data =[]; [a,~] = size(xdata);
            % for i=1:a
            %     nX = xdata{i,1}';nY = ydata{i,1}';nZ = zdata{i,1}';
            %     tmp = [nX,nY,nZ];
            %     cyl_data = [cyl_data;tmp];
            % end
            shp = alphaShape(newTable',parameters(7));
            indices = inShape(shp,testData);
            interData = testData(indices,:);
            % close(fig2)
    end

    function [sfM,sfM_G,obj] = fitmySurface(obj,data) 
        % The function finds the intersection between the surface and the cylinder
        % axis. "parameter" contains information [points1,points2,cyl_rad]
        % "data" contains information for the surface.
    %     nDir = Dir./norm(Dir);
        x_s = data(:,1);y_s = data(:,2);z_s = data(:,3);
        [sfM, sfM_G] = fit([x_s,y_s],z_s,"poly23");
        obj.sfM = sfM;
    end

    function res_Z = errorFunc_Surf(obj,t)
        % Function to minimise
        sfM = obj.sfM; p = obj.parameters;
        Dir = p(4:6) - p(1:3);
        ln_3D = p(1:3) + t*Dir; % This converts to x,y and z from t.
        x = ln_3D(1,1); y = ln_3D(1,2); z_ln = ln_3D(1,3);
        z = sfM.p00 + sfM.p10*x + sfM.p01*y + sfM.p20*x^2 + sfM.p11*x*y + sfM.p02*y^2 + sfM.p21*x^2*y + ...
            + sfM.p12*x*y^2 + sfM.p03*y^3;
        res_Z = (z_ln - z)^2;
    end


    function [ln_3D,pltM] = measuredPoint(obj,t,data)
        p = obj.parameters;
        Dir = p(4:6) - p(1:3);
        ln_3D = p(1:3) + t*Dir;
        apprxAns = mean(data);
        delTa = abs(ln_3D - apprxAns);
        cri = [.85,.85,.85]; ltn = ["cs","ks"];
        Bool = delTa>cri;
        if sum(Bool) >= 1
            pltM = ltn(1); ln_3D = apprxAns;
        else
            pltM = ltn(2);
        end
    end
    
    % function [axis,tt] = determineSI_Dir(obj)
    %     % This is used to determine the axial orientation i.e. This is used to determine the Superior - Inferior axis 
    %     pcData = pointCloud(obj.oriCoords);
    %     tt = pcfitplane(pcData,5);
    %     [~,axis] = max(abs(tt.Normal));
    % end
    % 
    % function [AP_Dir] = determineAP_Dir(obj)
    %     % To-DO. This is used to determine the AP direction for my knee - might not be true though. Need to check for all knees 
    %     valA = sum(pca(obj.oriCoords));
    %     [~,AP_Dir] = max(valA);
    % end
    
    function [tibiaEpiCoords] = calcTibiaFeatures(obj,medCoords,latCoords) %% - Done
        for i = 1:size(medCoords,1)-1
            tibiaEpiCoords.med(i,:) = medCoords(1,:) + medCoords(i+1,:);
            tibiaEpiCoords.lat(i,:) = latCoords(1,:) + latCoords(i+1,:);
        end
    end

    function [Points2Measure,newCentre] = PointsAroundMenisci(obj,tibiaEpiCoords,planeHeight,axes,displacements) % To - Do
        %% Important -- This code is a replica of what is in ScanIP("CalculateMenLocations.py") to allow congruency in results for optimisation purposes.
        ScalarA = 1.0; ScalarB = 1.5; ScalarC = 3.5; % These are definitions I visualised and liked in ScanIP - hence why Scalar is different for medial and lateral plateau points centres.
        if obj.mnmx == 0 % Default case
            D_vec = tibiaEpiCoords.lat(:,:) - tibiaEpiCoords.med(:,:); % This determines the points on the tibial plateaux that I measure bits from.
            lt = ["-","+"];
        elseif obj.mnmx == 1 % Only occurs for knee 5
            D_vec = tibiaEpiCoords.med(:,:) - tibiaEpiCoords.lat(:,:);
            lt = ["+","-"];
        end
        [a,~] = size(D_vec);
        tes = obj.generatePoints(70,6); % these are defined constants in ScanIP
        Points2Measure = struct();
        SI_Dir = axes(1); AP_Dir = axes(2);
        [~,obj] = obj.ResultantCoordinates(displacements);
        for it = 1:a
            % I will use newCentre to calc locations around the periphery of the menisci. The newcentre is calc based on two operations
            % 1. Using the direction vector based on tibial features 2. Modifying location using original tibia centres and translating by some amount.
            if obj.mnmx == 0 % Default case
                newCentre(it).med = tibiaEpiCoords.med(it,:) - ScalarA*D_vec(it,:);
                newCentre(it).lat = tibiaEpiCoords.lat(it,:) + ScalarB*D_vec(it,:); 
                newCentre(it).med(1,AP_Dir) = tibiaEpiCoords.lat(it,AP_Dir);
                newCentre(it).lat(1,AP_Dir) = tibiaEpiCoords.med(it,AP_Dir) - 6; % This value here "6" is based on definitions I made in ScanIP  
            elseif obj.mnmx == 1 % Only occurs for knee 5
                newCentre(it).med = tibiaEpiCoords.med(it,:) + ScalarB*D_vec(it,:);
                newCentre(it).lat = tibiaEpiCoords.lat(it,:) - ScalarA*D_vec(it,:); 
                newCentre(it).lat(1,AP_Dir) = tibiaEpiCoords.med(it,AP_Dir); 
                newCentre(it).med(1,AP_Dir) = tibiaEpiCoords.lat(it,AP_Dir) - 6;
            end

            newCentreA = [newCentre(it).med;newCentre(it).lat];
            DirV = D_vec(it,:).*ones(3,3); newcoord = [];
            for j = 1:2
                txt = "newCentreA(j,:) " + lt(j) +" (tmp*(ScalarC*D_vec(it,:))')'"; % Found that dot product is different in Matlab and Python
                for i = 1:6
                    tmp = obj.rotationMat(tes(i),SI_Dir);
                    new = eval(txt);
                    newcoord = [newcoord;new];
                end
            end
            % I make measurements on some given plane which corresponds to the planeHeight variable.
            constHeight = obj.pixelConv*planeHeight(it)+obj.avgheight;% this is to correct for the issue of modelling in Abaqus
            newcoord(:,SI_Dir)= constHeight; % this ".293" is the pixel resolution to convert to pixel height.
            newCentre(it).med(1,SI_Dir) = constHeight; 
            newCentre(it).lat(1,SI_Dir) = constHeight;
            Points2Measure(it).step = newcoord; 
        end
    end

    function [defCoords,obj] = ResultantCoordinates(obj,displacements)
        % This function finds the deformed coordinate given coordinates from the assembly in Abaqus.  
        a = obj.med_men_length;
        med_men = obj.oriCoords(1:a,:); lat_men = obj.oriCoords(a+1:end,:); % These are the coordinates of the medial and lateral menisci
        med_men_displ = displacements(1:a*4,:); lat_men_displ = displacements((a*4)+1:end,:); % This data is composed of 4 steps {Move,Load1, Load2 and load3} 
        [b,~] = size(lat_men_displ); %[a,~] = size(med_men_displ); 
        b = b/4;  ltA = [1,a+1,2*a+1,3*a+1]; ltB = [1,b+1,2*b+1,3*b+1];
        mVal = mean(med_men_displ(1:a,obj.axes(1))); lVal = mean(lat_men_displ(1:b,obj.axes(1)));
        obj.mVal_lVal = [mVal,lVal]; %% Correction - calc
        obj.avgheight = ( mVal + lVal )/2; %% Correction - calc Average of movement in the meniscus
        for it =1:4
            defCoords(it).med = med_men + med_men_displ(ltA(it):a*it,:);
            defCoords(it).lat = lat_men + lat_men_displ(ltB(it):b*it,:);
        end
        obj.defCoords = defCoords;
        % This is a structure with each row corresponding to the load step{Move, Load1, Load2,Load3}
    end

    function [results, obj] = EstimateMenisciDisplacements(obj,Points2Measure,displacements)
        cyl_rad =1.5; % this will be modified until suitable value is found{Verify by plotting}
        [~,obj] = obj.ResultantCoordinates(displacements); % These are the coordinates after displacements 
        ltn = ["med_men","lat_men"]; % Separates the data into lateral and medial
        nlt = ["trp(1:6,:)","trp(7:12,:)"];  % These are the points plotted around the periphery of the menisci
        for it=1:size(Points2Measure,2)
            trp = Points2Measure(it).step;
            revCoords = [obj.revCentres(it).med;obj.revCentres(it).lat];
            med_men = obj.defCoords(it).med;
            lat_men = obj.defCoords(it).lat;
            for j=1:2
                trpn = eval(nlt(j)); measuredCoords = [];
                data = eval(ltn(j)); boolCoords = [];
                for i=1:6  %% To-Do -> I believe that the plot is causing the problem.
                    % dirVec = trpn(i,:) - revCoords(j,:);
                    parameters = [revCoords(j,:),trpn(i,:),cyl_rad];
                    % cyl_mod = cylinderModel(parameters);
                    % plot(cyl_mod); legend("AutoUpdate","off")
                    % Generating and checking values that intersect with the cylinder
                    [IntData,cyl_mod] = obj.cylinderIntersect(parameters,data);
                    % plot3(oriAx,IntData(:,1),IntData(:,2),IntData(:,3),"yo","DisplayName","Measure surface")
                    % legend('AutoUpdate', 'off')
                    % Fit surface and find intersect with cylinder axis
                    if size(IntData,1)>=9
                        sfM = obj.fitmySurface(IntData);
                        obj = obj.variables(parameters,sfM);
                        Con_X = fsolve(@obj.errorFunc_Surf,1);
                        [point,pltM]= obj.measuredPoint(Con_X,IntData);
                        if isnan(point)
                            point = mean(IntData,1);
                        end
                    else
                        pltM = "rs"; % These are approximate solutions.
                        if isempty(IntData)
                            parameters(7) = 2.5; % Increase the radius to try and capture more points.
                            [IntData,cyl_mod] = obj.cylinderIntersect(parameters,data);
                            point = mean(IntData,1);
                        else
                            point = mean(IntData,1); %[Solve for t == Con_X] this is the case where there is not enough data for data fitting.
                        end
                    end
                    measuredCoords = [measuredCoords;point];
                    boolCoords = [boolCoords;pltM];
                    % plot3(oriAx,point(:,1),point(:,2),point(:,3),pltM,"MarkerSize",5,"LineWidth",2)
                end
                if j ==1
                    obj.results(it).med = measuredCoords;
                    obj.results(it).medPlot = boolCoords;
                    obj.results(it).medDispl = sqrt(sum((revCoords(j,:) - measuredCoords).^2,2));
                else
                    obj.results(it).lat = measuredCoords;
                    obj.results(it).latPlot = boolCoords;
                    obj.results(it).latDispl = sqrt(sum((revCoords(j,:) - measuredCoords).^2,2));
                end
            end
        end
        results = obj.calcDisplacements();
    end

    function [displacements] = calcDisplacements(obj)
        a = size(obj.revCentres,2);
        displacements = zeros(a,12);
        for it = 1:a
            displacements(it,:)=[obj.results(it).medDispl;obj.results(it).latDispl]';
        end
    end

    function [obj] = collectkneeDetails(obj,kneeName)
        test = upper(kneeName); obj.mnmx = false;
        if test == "KNEE 2"
            obj.axes = [3,2];
            obj.pixelConv = .15;
            obj.path = "MatlabOutput\Knee 2";
        elseif test == "KNEE 4"
            obj.axes = [3,2];
            obj.pixelConv = .293;
            obj.path =  "MatlabOutput\Knee 4";
        elseif test == "KNEE 5"
            obj.axes = [2,3];
            obj.pixelConv = .293;
            obj.path =  "MatlabOutput\Knee 5";
            obj.mnmx = true; % This is the case where the SI is pointing downs instead of upwards hence causes issues in code.
        end
        % py.importlib.import_module('HelperFunc');
        % val = py.HelperFunc.checkInpfile(kneeName);
        % try
        %     py.HelperFunc.initialise();
        % catch
        % end
        % if val == 0
        %     error("Ensure the right Abaqus file i.e .inp file is in the root directory")
        % end
    end

    function [data] = findFiles(obj,path)
        data = py.HelperFunc.findFiles(path);
    end

    function [param] = findParameters(obj,path)
        path = py.str(path);
        param = py.HelperFunc.findParameters(path);
    end

    function [obj] = resetData2Store(obj)
        obj.defCoords =[];
        obj.oriCoords =[];
    end
    
    function [obj] = optimisationControl(obj,Scalar_weights)
        if exist("Scalar_weights",'var')
            obj.weights = Scalar_weights;
        else % this is the default where we dont control which node the optimisation uses.
            ff = fullfile(obj.path,"expData.mat"); load(ff); [a,b] = size(expData);
            obj.weights = ones(a,b);
        end
    end

end
end

