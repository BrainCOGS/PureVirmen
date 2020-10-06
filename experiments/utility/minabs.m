function [value, index] = minabs(array, varargin)

  [~, index]  = min(abs(array), varargin{:});
  value       = array(index);

end

