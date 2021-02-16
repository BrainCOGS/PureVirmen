function vr = change_colors_inside_region(vr)
%CHANGE_COLORS_CUE_MICRO_REGIONS Summary of this function goes here
%   Detailed explanation goes here

params = vr.protocol_file.extra_params.change_colors_cue_micro_regions;

idx_region   = vr.virmen_structures.regions.region_table.region_name == params.region;
region_start = vr.virmen_structures.regions.region_table.cross(idx_region);
region_end   = vr.virmen_structures.regions.region_table.cross(idx_region+1);
region_length = region_end - region_start;

both_length = region_length - (params.left_ratio + params.right_ratio)*region_length;

all_lengths  = [0 both_length params.left_ratio*region_length params.right_ratio*region_length];
cum_distance = cumsum(all_lengths)+region_start;

colors = [[0 1 0]; [1 0 0];[0 0 1];[0.5 0.5 0]];
idx = 1;
for i=fliplr(cum_distance)
    
    if vr.position(2) >= i
        vr.worlds{vr.currentWorld}.backgroundColor  = colors(idx,:);
    end
    
    idx = idx + 1;
end

end

