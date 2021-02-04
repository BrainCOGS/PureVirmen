function send_region_signal(vr, signal_dict, region_struct, region_idx )
%SEND_REGION_SIGNAL send a signal to bcontrol when a region was reached
% Inputs
% signal_dict    = signal dictionary agreed between virmen and bcontrol
% region_struct  = structure with all region information
% region_idx     = index of region reached

region_name = region_struct.region(region_idx);
region_entry_signal = [region_name '_entry'];
vr.BpodMod.sendEvent(signal_dict(region_entry_signal));
                   

end

