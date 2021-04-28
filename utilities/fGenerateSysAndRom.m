function [sys_dExt, rom] = fGenerateSysAndRom(path_ssm, Ts, x0_value, orders)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generate a discrete state space model from the continus SSM obtained
    % from dymola and reduce it to ROM's of different orders. The SSM are
    % also augmented in order to include to the non-zero initial conditions
    % (see section 3.3.2 in paper: 
    %  Picard D., Drgo?a J., Kvasnica M., Helsen L. (2017). Impact of  
    %  the controller model complexity on model predictive control 
    %  performance for buildings. Energy and Buildings, 152, 739-751.)
    %
    % :param:
    %   path_ssm: path to the state space model ssm
    %   Ts: sampling time of discrete SSM
    %   x0_value: initial state values. This must either be a vector of same
    %   length as the number of states or a unique value which will be used
    %   for all states.
    %   orders: list of orders to which the SSM should be reduced
    % :outputs:
    %   sys_dExt:
    %   rom:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin < 2 
        path_ssm = '../examples/zoneWithInputs/ssm.mat';
        Ts = 1200;
        x0_value = 293.15;
        orders = [5, 10];
    end
    
    load(path_ssm);
    nx = size(A,1);

    %% Extend state space to include initial conditions. See paper
    % x+ = Ax + [B x0] [u 1]'
    % y = Cx + [D Cx0] [u 1]'
    if length(x0_value) == 1
        x0 = x0_value .* ones(nx,1);
    else
        x0 = x0_value;
    end;
    BExt = [B A*x0];
    DExt = [D C*x0];
    
    %% Discretize SSM
    sys_dExt = c2d(ss(A,BExt,C,DExt),Ts);
    
    %% Reduce SSM to different orders
    rom = cell(length(orders),1);
    for i = 1:length(orders)
        rom{i} = reduce(sys_dExt, orders(i));
    end;

end
