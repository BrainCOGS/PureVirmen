classdef GeneralParameters

  properties (Constant)
    
    mini_vr_proj_parameters = {'Rs', 'xsm', 'ysm', 'zsm', ...
                               'xOm', 'yOm', 'zOm', 'r', ...
                               'xP1o' 'yP1o', 'zP1o', ...
                               'hrescaling', 'hshift', ...
                               'vrescaling', 'vshift'};
    
    mini_vr_proj_parameters_full = strcat('proj_param_', GeneralParameters.mini_vr_proj_parameters)
                           
    
    %                                            T5                      T10                      T15                      T20                      T25                      T30 
    DEFAULT_REWARD_FACTOR = [[ 2, 1.5, 1.2,   1,   1, 1.2, 1.2, 1.2, 1.2, 1.2, 1.4, 1.5, 1.6, 1.8, 1.8, 1.8 ...
                             ;1,   1,   1,   1,   1,   1,   1,   1,   1,   1, 1.2, 1.2, 1.2, 1.2, 1.2, 1.2 ...
                             ] repmat([1.8; 1.2], 1, 100)]
  end
   
end
