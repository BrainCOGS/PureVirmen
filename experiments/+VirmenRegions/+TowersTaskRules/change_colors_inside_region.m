function vr = change_colors_inside_region(vr)
%CHANGE_COLORS_CUE_MICRO_REGIONS Summary of this function goes here
%   Detailed explanation goes here

params = vr.virmen_structures.protocol_file.extra_params.change_colors_inside_region;

idx_region   = vr.virmen_structures.regions.region_table.region_name == params.region;
region_start = vr.virmen_structures.regions.region_table.cross{idx_region}.crossing;
region_end   = vr.virmen_structures.regions.region_table.cross{circshift(idx_region, 1)}.crossing;
region_length = region_end - region_start;

both_length = region_length - ...
    (params.only_left_towers_ratio + params.only_right_towers_ratio)*region_length;

all_lengths  = [0 both_length ...
    params.only_left_towers_ratio*region_length  ...
    params.only_right_towers_ratio*region_length];
cum_distance = cumsum(all_lengths)+region_start;

colors = [[0 1 0]; [1 0 0];[0 0 1];[0.5 0.5 0]];
idx = 1;
for i=fliplr(cum_distance)
    
    if vr.position(2) >= i
        vr.worlds{vr.currentWorld}.backgroundColor  = colors(idx,:);
        break
    end
    
    idx = idx + 1;
end

end

