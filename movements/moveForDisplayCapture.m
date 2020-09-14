function velocity = moveForDisplayCapture(vr)
  
  %% Start after a specified number of initial iterations
  velocity      = [0 0 0 0];
  iterations    = vr.iterations - 5;
  if iterations < 1
    return;
  end
  
  %% Use even iterations to generate velocity and odd iterations to capture the screen
  index         = ceil(iterations/2);
  if index > size(vr.exper.userdata.simPositions,1)
    error('moveForDisplayCapture:done', 'This is a hack to stop after capturing the desired number of frames.');
  end
  
  if mod(iterations,2)
    %% Compute the required velocity to jump to the desired position
    dp          = vr.exper.userdata.simPositions(index,:) - vr.position;
    velocity    = dp / vr.dt;
    
  else
    %% Deduce how to name the output so that it doesn't overwrite existing files
    tag         = [sprintf('_%.3g', vr.exper.userdata.simPositions(index,:)), '.png'];
    existing    = dir([vr.exper.userdata.capturePath, '*', tag]);
    existing    = arrayfun(@(x) x.name(1:end-numel(tag)), existing, 'UniformOutput', false);
    existing    = regexp(existing, '[0-9]+$', 'match', 'once');
    if isempty(existing)
      outIndex  = 1;
    else
      outIndex  = max(cellfun(@str2double, existing)) + 1;
    end
    
    %% Perform and save screen capture 
    snapshot    = virmenGetFrame(1);
    outFile     = sprintf('%s%d%s', vr.exper.userdata.capturePath, outIndex, tag);
    imwrite(snapshot, outFile);
    
  end
  
end
