function vr = trial_tcp_data(vr)
%trial_tcp_communication
% Send trial information through tcp

% If communication is activated
if vr.act_comm
    
    %Get time of trial
    time = single(vr.logger.currentTrial.time(vr.logger.currentIt,1));
    
    %Get position and velocity
    serialdata = typecast([single(vr.position(ExperimentLogMin.SPATIAL_COORDS)) ...
        single(vr.velocity(ExperimentLogMin.SPATIAL_COORDS)) ...
        time],'uint8');
    
    %Get sensor info
    if ~isempty(vr.sensorData)
        serialdata = [serialdata ...
            typecast(vr.sensorData(ExperimentLogMin.SENSOR_COORDS), 'uint8')];
    else
        serialdata = [serialdata uint8(zeros(1, numel(ExperimentLog.SENSOR_COORDS)*2))];
    end
    
    %Concatenate all data
    serialdata = [serialdata  uint8(vr.collision)];
    serialdata = double(serialdata);
    
    %Write it to tcp_port
    fwrite(vr.tcp_client, serialdata)
    
end

end