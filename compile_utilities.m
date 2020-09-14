function compile_utilities()

% Only support modern enough compilers
cCompiler   = mex.getCompilerConfigurations('C','Selected');
if      ~strncmpi(cCompiler.ShortName', 'msvc', 4)  ...
    ||  str2double(cCompiler.Version) < 11
  fprintf('!!  WARNING:  This is only supported for Microsoft Visual C++ 2012 and newer. Doing nothing.\n');
  return;
end


% Code files to compile
code        = { 'priority.cpp'    ...
              , 'binarySearch.c'  ...
              };
objCode     = { {'Gamma.cpp', 'binointerval.cc'}  ...
              };


% NI-DAQ environment
mexOpts     = { '-O'                                                              ...
              };
            
% Change to the directory that hosts this file (and by assumption the mex code)
origLoc     = cd(fullfile(fileparts(mfilename('fullpath')), 'experiments\utility'));

for iCode = 1:numel(code)
  fprintf('====================  Compiling %s  ====================\n', code{iCode});
  mex(code{iCode}, mexOpts{:});
end

for iCode = 1:numel(objCode)
  fprintf('====================  Compiling %s  ====================\n', objCode{iCode}{end});
  objFiles  = {};
  for iObj = 1:numel(objCode{iCode})-1
    objPath = fullfile('private', objCode{iCode}{iObj});
    mex('-outdir', 'private', '-c', '-O', objPath);
    objPath = rdir( regexprep(objPath, '[.][^.]+$', '.o*') );
    objFiles{end+1} = objPath.name;
  end
  mex(objCode{iCode}{end}, objFiles{:}, mexOpts{:});
end

cd(origLoc);

