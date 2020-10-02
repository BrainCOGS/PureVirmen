function makepath(filePath)

  dir   = parsePath(filePath);
  if ~exist(dir, 'dir')
    mkdir(dir);
  end

end
