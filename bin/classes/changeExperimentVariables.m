function changeExperimentVariables(src,evt) %#ok<INUSL>

obj = evt.AffectedObject;

% Determine which variables got updated
fldold = fieldnames(obj.backedUpVariables);
fldnew = fieldnames(obj.variables);
fldboth = intersect(fldold,fldnew);
upd = setdiff(union(fldold,fldnew),fldboth);
for ndx = 1:length(fldboth)
    if ~strcmp(obj.variables.(fldboth{ndx}),obj.backedUpVariables.(fldboth{ndx}))
        upd{end+1} = fldboth{ndx}; %#ok<AGROW>
    end
end

if isempty(upd)
    return
end

dsc = obj.descendants;
for ndx = 1:length(dsc)
    props = fieldnames(dsc{ndx}.symbolic);
    for p = 1:length(props)
        hasVar = false;
        pattern = sprintf('%s|', upd{:});
        pattern = ['(?:^|[^A-Za-z0-9_])(?:' pattern(1:end-1) ')(?:$|[^A-Za-z0-9_])'];
        
        if ischar(dsc{ndx}.symbolic.(props{p}))
            if ~isempty(regexp(dsc{ndx}.symbolic.(props{p}), pattern, 'once'))
                hasVar = true;
            end
        else
            for s = 1:length(dsc{ndx}.symbolic.(props{p}))
              if ~isempty(regexp(dsc{ndx}.symbolic.(props{p}){s}, pattern, 'once'))
                hasVar = true;
                break;
              end
            end
        end
        if hasVar
            dsc{ndx}.(props{p}) = dsc{ndx}.symbolic.(props{p});
        end
    end
end