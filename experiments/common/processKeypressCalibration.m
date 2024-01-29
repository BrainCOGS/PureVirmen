%% Some standard ways in which user keypress can be used to control a ViRMen experiment.
function [idx_param, change_param]  = processKeypressCalibration(vr)

  change_param = [];
  
               %1:9   0   -   U   I   O   P  
  code_param = [49:57 48, 45, 85, 73, 79, 80];
  idx_param = find(code_param == vr.keyPressed);
    
   if ~isnan(vr.keyPressed)
       disp(num2str(vr.keyPressed))
   end
  
  switch vr.keyPressed
      case 81  % Q
          change_param = .1;
      case 65  % A
          change_param = -.1;
      case 87  % W
          change_param = .01;
      case 83  % S
          change_param = -.01;
      case 69  % E
          change_param = 0.001;
      case 68  % D
          change_param = -0.001;
  end
          
end
