function [ vr ] = send_event_BPOD( vr )
%SEND_EVENT_BPOD 
% Read command and Send signal through BPOD 

if vr.act_comm
    event = vr.BpodMod.readEvent();
    if event ~= -1

        if char(event(1)) == 'C'
            color = event(2);
            if color == 1
                vr.countcolor = vr.countcolor + 1;
                if vr.countcolor > length(vr.colormap)
                    vr.countcolor = 1;
                end

                vr.worlds{vr.currentWorld}.backgroundColor  = vr.colormap(vr.countcolor, :);
            end

        end

    end
    %vr.BpodMod.sendEvent(1);

end


end

