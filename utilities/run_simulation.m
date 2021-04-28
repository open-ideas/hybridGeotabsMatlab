function run_simulation(reload, nStep, ROM_orders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Function to simulate the state space model (SSM) and reduced state space
    % model (ROM). The disturbances and prescribed variables are loaded
    % using distrubances.m and the SSM and ROMs are created using
    % fGenerateSysAndRom.m. The SSM and ROMs outputs can also be plotted
    % and compared.
    % :param:
    %   reload   = set to true if ssm.mat and/or outputs.mat has changed.
    %   If reload is true, a new discrete SSM (and ROM) will be generated
    %   and the disturbances will be reloaded using the disturbance
    %   function. The result is saved in the tmp/ folder.
    %   nStep    = number of discrete time step to simulate.
    %   ROM_orders   = list of orders to generate ROM
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin < 2
        addpath(pwd);
		cd('../examples/test/');
        reload = 1;
        nStep = 400;
        ROM_orders = [5, 10];
    end;

	%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Load disturbances and model 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if reload
        fprintf('*** Load disturbances ... \n')
		% Disturbances
        [t, v, inputIndexForDisturbances, dictCtlInputs, dictOutputNameIndex, dicValVar, x0] = disturbances(pwd,0, 0);
		save('tmp/dis.mat', 't', 'v', 'inputIndexForDisturbances', 'dictCtlInputs', 'dictOutputNameIndex','dicValVar', 'x0');
		fprintf('*** Done.\n')
        
		% Model
		fprintf('*** Create discrete SSM and ROM models ...\n')
        Ts = t(2) - t(1);
		[sys_dExt, rom] = fGenerateSysAndRom(['ssm.mat'], Ts, x0, ROM_orders);      
		save('tmp/mod.mat', 'Ts', 'ROM_orders', 'sys_dExt', 'rom');
   		fprintf('*** Done.\n')
    else
        fprintf('*** Load disturbances and ROM model...\n')
		load('tmp/dis.mat');
		load('tmp/mod.mat');
        fprintf('*** Done.\n')
	end;


	%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Simulate discrete SSM
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('*** Simulate SSM model ...\n')
	% Parameters
	t_ind_start = 1;
	index_t = t_ind_start:1:t_ind_start+nStep-1;
	mod = sys_dExt;

	%%%% Input vector (only disturbances, control inputs are set to zero).
	nu = size(mod.B,2);
	% Initialization of the input vector
	u = zeros(nStep,nu);
	% Add input = 1 for initialization
	u(:,end) = ones(nStep,1);
	% Couple the disturbances
	u(:,inputIndexForDisturbances) = v(1:nStep,:);
    % Set the control inputs to zero
    inputIndexForCtrl = cell2mat(dictCtlInputs.values());
    u(:,inputIndexForCtrl) = zeros(nStep,length(inputIndexForCtrl));

	% Simulate
	y_ssm = lsim(mod, u, t(index_t));
    fprintf('*** Done.\n')
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Simulate ROMs
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('*** Simulate ROMs ...\n')
    n_roms = length(ROM_orders);
    y_roms = cell(n_roms,1);
    for i_rom = 1:n_roms
        fprintf(['*** Simulate ROM-' num2str(ROM_orders(i_rom)) ' ...\n'])
        y_roms{i_rom} = lsim(rom{i_rom}, u, t(index_t));
    end;
    fprintf('*** Done.\n')
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Plot SSM and ROMs outputs
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
	% ---- Plot operative temperatures
    fprintf('*** Plot results ...\n')
    
    % Make one figure per output
    n_rom = length(ROM_orders);
    leg = cell(n_rom + 1,1);
    for outputKey = dictOutputNameIndex.keys()
        figure()
        ind_output = dictOutputNameIndex(outputKey{1});
        plot(t(index_t),y_ssm(:,ind_output)), title(outputKey{1}), hold on,
        leg{1} = 'SSM';
        for i_rom = 1:n_rom
            plot(t(index_t),y_roms{i_rom}(:,ind_output));
            leg{1+i_rom} = ['ROM-' num2str(ROM_orders(i_rom))];
        end;
        legend(leg); hold off
    end;
end
