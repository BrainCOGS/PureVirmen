function [dataFcn, dataStr, dataMax] = smallestUIntStorage(dataMax)

  dataMax       = ceil(dataMax);
  for numBits = [8 16 32 64]
    if dataMax <= 2^numBits
      dataStr   = sprintf('uint%d', numBits);
      dataFcn   = str2func(dataStr);
      return;
    end
  end

  error('smallestUIntStorage:dataMax', 'Data with maximum value = %.5g exceeds all possible unsigned integer storage.', dataMax);
  
end
