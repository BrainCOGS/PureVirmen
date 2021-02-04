function vr = cue_onset_signal( vr )
% Send a signal to bcontrol when a cue has appeared
 
%% Loop through cues on both sides of the maze
for iSide = 1:numel(Choice.all())
        
        %Check if final onset is this iteration
        onsets = vr.cueOnset{iSide}(vr.cueAppeared{iSide});
        if ~isempty(onsets)
            final_onset = onsets(end);

            if final_onset == vr.logger.iterationStamp()
               vr.BpodMod.sendEvent(...
               vr.virmen_structures.signal_dict.signal_dict_virmen('cue_onset'));
            end
        end
end

end


