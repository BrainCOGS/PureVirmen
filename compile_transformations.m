function compile_transformations()

% Code files to compile
code        = { 'transformToroidalParametrizedMex.c'    ...
              };

% Variables that are passed to the mex file compilation as preprocessor defines
variables   = { sprintf('-DTOROIDP1=%.4g', RigParameters.toroidXFormP1) ...
              , sprintf('-DTOROIDP2=%.4g', RigParameters.toroidXFormP2) ...
              };

% Change to the directory that hosts this file (and by assumption the mex code)
origLoc     = cd(fullfile(fileparts(mfilename('fullpath')), 'transformations'));

for iCode = 1:numel(code)
  fprintf('====================  Compiling %s  ====================\n', code{iCode});
  mex(code{iCode}, '-O', variables{:});
end

cd(origLoc);
