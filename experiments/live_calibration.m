function code = live_calibration
% manuel_calibration   Code for the ViRMEn experiment manuel_calibration.
%   code = manuel_calibration   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT

% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

    %Check if all parameters for calibration exist on rigParameters file
    vr.proj_params = [];
        all_params = GeneralParameters.mini_vr_proj_parameters_full;
        has_all_parms =1;
        for i=1:length(all_params)
            if ~isprop(RigParameters, all_params{i})
                has_all_parms = 0;
            else
                %Set parameters for virmenEngine function
                vr.proj_params(i) = RigParameters.(all_params{i});
            end   
        end
        %If rigParameters doesn't have all parameters, transformation embedded in file
       if has_all_parms
        vr.exper.transformationFunction = @miniVR_projection_wparameters;
       else
        vr.exper.transformationFunction = @miniVR_projection;
       end

    vr.param_list = GeneralParameters.mini_vr_proj_parameters;
    
    vr.param_key  = ['1', '2', '3', '4', ...
                     '5', '6', '7', '8', ...
                     '9', '0', '-', 'U', 'I', 'O', 'P'];
    
    vr.num_param = 1;
    vr.change_param = [];
    
    %Check if there were missing parameters for projection in RigParameters
    if length(vr.proj_params) < length(vr.param_list)
        all_params = GeneralParameters.mini_vr_proj_parameters_full;
        s = [];
        fprintf('== Missing proj params in RigParameters ==\n');
        for i=1:length(all_params)
            if ~isprop(RigParameters, all_params{i})
                s = [s sprintf(' %s\n', all_params{i})];
            end   
        end
        error(['Cannot run live calibration with missing parameters:' newline s]);
    end
    
    display_params(vr)
    
% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

    [num_param, vr.change_param] = processKeypressCalibration(vr);
    if ~isempty(num_param)
        vr.num_param = num_param;
    end
    
    if ~isempty(vr.change_param)     
        vr.exper.userdata.proj_params(vr.num_param) = vr.exper.userdata.proj_params(vr.num_param) + vr.change_param;
    end
    
    if ~isempty(num_param) || ~isempty(vr.change_param)
         display_params(vr)
    end

% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

function display_params(vr)

    clc
    if ~isempty(vr.change_param)
        fprintf('====== Last command ======\n')
        if vr.change_param > 0
            ch = '+';
        else
            ch = '-';
        end
        fprintf('   (%s) %s %s%2.3f\n', vr.param_key(vr.num_param), vr.param_list{vr.num_param}, ch, abs(vr.change_param));
    end
    
    fprintf('\n====== Proj Params ======\n')
    for i=1:length(vr.param_list)
        if i== vr.num_param
            fprintf('-> ');
        else
            fprintf('   ');
        end
        fprintf('(%s) %s = %2.3f \n', vr.param_key(i), vr.param_list{i}, vr.exper.userdata.proj_params(i));
    end
    fprintf('\n====== Controls (applied to selected "->" param ) ======\n' );
    fprintf('(Q) -> + 0.1           (A) -> - 0.1  \n');
    fprintf('(W) -> + 0.01          (S) -> - 0.01 \n');
    fprintf('(E) -> + 0.001         (D) -> - 0.001\n');
    fprintf(' \n');
