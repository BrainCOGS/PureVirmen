function close_all_comm( )
%CLOSE_ALL_COMM
% closes all previously opened communications

% Clean up any open lines e.g. from ViRMEn crashes
openInstr = instrfindall;
if ~isempty(openInstr)
    fclose(openInstr);
end

end

