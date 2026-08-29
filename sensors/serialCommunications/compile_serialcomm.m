function compile_serialcomm()

  % Serial.cpp uses the Windows COM-port API
  if ~ispc
    fprintf('!!  WARNING:  Serial communications MEX is only supported on Windows. Doing nothing.\n');
    return;
  end

  % Compilation options
  mexOpts       = {'-O'};

  % MEX programs and supporting classes
  code          = { {'Serial.cpp', 'arduinoReader.cpp'}   ...
                  };

  %========================================================================
  codeDir       = fileparts(mfilename('fullpath'));
  origDir       = cd(codeDir);
  
  for iCode = 1:numel(code)
    fprintf('====================  Compiling %s  ====================\n', code{iCode}{end});
    objFiles  = {};
    for iObj = 1:numel(code{iCode})-1
      objPath = fullfile('private', code{iCode}{iObj});
      mex('-outdir', 'private', '-c', objPath, mexOpts{:});
      objPath = rdir( regexprep(objPath, '[.][^.]+$', '.o*') );
      objFiles{end+1} = objPath.name;
    end
    mex(code{iCode}{end}, objFiles{:}, mexOpts{:});
  end
  
  cd(origDir);
  clear('mex');

end
