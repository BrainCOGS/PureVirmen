function vr = cue_onset_signal( vr )
% Send a signal to bcontrol when a cue has appeared
 
%% Loop through cues on both sides of the maze
choices = Choice.all();
for iSide = 1:numel(choices)
        
        %Check if final onset is this iteration
        onsets = vr.cueOnset{iSide}(vr.cueAppeared{iSide});
        if ~isempty(onsets)
            %ALS not always last onset is max onset why??
            final_onset = max(onsets);
            %[final_onset vr.logger.iterationStamp()]
            
            if final_onset == vr.logger.iterationStamp()
                if choices(iSide) == Choice.L
                    vr.BpodMod.sendEvent(...
                    vr.virmen_structures.signal_dict.signal_dict_virmen('left_cue_onset'));
                else
                    vr.BpodMod.sendEvent(...
                    vr.virmen_structures.signal_dict.signal_dict_virmen('right_cue_onset'));
                end
            end
        end
end

end


