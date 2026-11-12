function install_virmen()

[scriptDir,scriptName]  = fileparts(mfilename('fullpath'));
origLoc                 = cd(scriptDir);

if exist('git-hooks', 'dir')
  fprintf('::  Copying git hooks...\n');
  copyfile('git-hooks/*', '.git/hooks');
end

fprintf('::  Logging git status to version.txt...\n');
system('git log -1 --pretty=oneline HEAD > version.txt');


try
  
  fprintf('::  Compiling ViRMEn display transformations...\n');
  compile_transformations

  fprintf('::  Compiling external utilities...\n');
  compile_utilities
  compile_serialcomm
  compile_daqcomm

  fprintf([ '\n\n'                                                                    ...
            '          **********  INSTALLATION COMPLETE  **********\n'               ...
            '   Run compile_transformations manually whenever calibration\n'          ...
            '   constants have been changed in RigParameters.m.\n'                    ...
            '\n\n'                                                                    ...
         ]);
       
catch err
  
  fprintf([ '\n\n'                                                                    ...
            '   The following error occurred when trying to compile MEX files\n'      ...
            '   required by this software. Please make sure that RigParameters.m\n'   ...
            '   is properly configured, and then re-run ' scriptName '.\n'            ...
            '\n\n'                                                                    ...
         ]);
  disp(getReport(err));
  
end

cd(scriptDir);
     
if exist('extras/RigParameters.m', 'file')
  if ispc
    system('start winmerge extras/RigParameters.m extras/RigParameters.m.example');
  end
  fprintf('::  Please edit your existing RigParameters.m to match RigParameters.m.example.\n');
else
  copyfile('extras/RigParameters.m.example', 'extras/RigParameters.m');
  edit('extras/RigParameters.m');
  fprintf('::  A default RigParameters.m has been created, please edit it as appropriate.\n');
end

cd(origLoc);
