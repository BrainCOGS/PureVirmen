%----- To be called at the end of each trial to get missing virmen fields
function trial_fields = get_specific_virmen_trial_fields(~, vr)

%Get missing fields from vr

% cue onset and offset logs
trial_fields.cue_onset_left     = {vr.cueOnset{Choice.L}};
trial_fields.cue_onset_right    = {vr.cueOnset{Choice.R}};
trial_fields.cue_offset_left    = {vr.cueOffset{Choice.L}};
trial_fields.cue_offset_right   = {vr.cueOffset{Choice.R}};

% Entry to regions log
region_table                    = vr.virmen_structures.regions.region_table;
trial_fields.i_cue_entry        = region_table{region_table.region == 'cues',   'entry'};
trial_fields.i_mem_entry        = region_table{region_table.region == 'memory', 'entry'};
trial_fields.i_turn_entry       = region_table{region_table.region == 'turn',   'entry'};
trial_fields.i_arm_entry        = region_table{region_table.region == 'arms',   'entry'};
trial_fields.i_blank            = vr.iBlank;

% Distance traveled variables
trial_fields.maze_length        = vr.mazeLength;

end