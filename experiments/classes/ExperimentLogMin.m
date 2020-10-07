%% Book-keeping tool for ViRMEn experiments.
%
% Creating an object of this class starts collecting data for a log file
%
% Each log file is specific to an animal and a training day and a session number.
%
%
% IMPORTANT:
%   Since ViRMEn performs behavioral updates in discrete frames, timestamps
%   are recorded based on vr.dt, which is the duration of the *previous*
%   frame. This means that the stored time is the *start* of the current
%   frame (relative to the start of the trial). If the user wants to record
%   other events he/she should then use the ViRMEn iteration number
%   vr.iterations instead of independent timestamps, particularly when it is 
%   not meaningful to subdivide events that happen within the frame e.g.
%   because it will anyway only take effect on the next ViRMEn iteration.
%
%
% The constructor takes a structure object whose fields determines what
% will be stored in the log. The following fields are required:
%   logPath           : Output path of the log file
%   trialData         : Cell array of strings, each of which corresponds to
%                       a field (in the vr structure) of per-trial data to
%                       be logged. 
%   savePerNTrials    : Interval in terms of number of trials to save the
%                       logged data to disk. If set to inf, data will not
%                       be logged automatically and you have to explicitly 
%                       call the save() function.
%   totalTrials       : Total number of trials for storage preallocation.
%
% The following functions should be called by the user to log various types
% of information in the course of the experiment:
%   save()            : This is automatically called at the specified
%                       savePerNTrials. However it should also be called
%                       explicitly by the user at the end of an experiment,
%                       e.g. in the ViRMen terminationCodeFun() function,
%                       so as to flush remaining data to disk.
%   logStart()        : Call this at the beginning of each trial to log the
%                       time.
%   logTick()         : Call this in the ViRMen runtimeCodeFun() so that
%                       position and velocity data can be stored per
%                       iteration. IMPORTANT: This should be called at
%                       *every* iteration including the ones where
%                       logStart() and logEnd() have been called.
%                       Furthermore it should always be called after those
%                       functions, so that e.g. the start of a new entry
%                       for the next trial can be performed before logging
%                       data into it.
%   logEnd()          : Call this at the end of each trial, i.e. probably
%                       somewhere in the ViRMen runtimeCodeFun() function,
%                       to store data for that trial. Remember that this
%                       should be done before changing trial information
%                       variables.
%   logExtras()       : Call this to handle blocking inputs like comments
%                       after the end of a trial (e.g. inter-trial
%                       interval). If a finite savePerNTrials is specified,
%                       the log object can be saved to disk in this call.

classdef ExperimentLogMin < handle

  %------- Constants
  properties (Constant)
    
    SPATIAL_COORDS  = [1 2 4];      % Columns of vr.position and vr.velocity to store
    SENSOR_COORDS   = 1:5;          % Columns of raw sensor readout to store
%     SENSOR_COORDS   = 1:7;          % Columns of raw sensor readout to store
    SENSOR_DATASIZE = 'int16';      % Data type specifier for raw sensor readout
    
    DEFAULT_PREALLOCSIZE  = 10000   % Default size of arrays to preallocate
    PREALLOCATED_FIELDS   = {
                              'position'      ...
                            , 'velocity'      ...
                            , 'sensorDots'    ...
                            , 'collision'     ...
                            , 'time'          ...
                            }
    
    DEFAULT_PATH          = 'C:\Data\'
    
    POSITION_SAMPLE       = nan(0, numel(ExperimentLogMin.SPATIAL_COORDS), 'single');
    VELOCITY_SAMPLE       = nan(0, numel(ExperimentLogMin.SPATIAL_COORDS), 'single');
    SENSORDOTS_SAMPLE     = zeros(0, numel(ExperimentLogMin.SENSOR_COORDS), ExperimentLogMin.SENSOR_DATASIZE);
    
    TRAIL_COMM_SAMPLE     = struct('position',   ExperimentLogMin.POSITION_SAMPLE, ...
                                   'velocity',   ExperimentLogMin.VELOCITY_SAMPLE, ...
                                   'sensorDots', ExperimentLogMin.SENSORDOTS_SAMPLE);  
               
    TRAIL_COMM_SAMPLE_STRUCT_MAP = ...
        comm.utility.get_struct_map(ExperimentLogMin.TRAIL_COMM_SAMPLE)                      
  end
  
  %------- Private data
  properties (Access = protected, Transient)
    trialInfo                       % Storage structure for per-trial info
    emptyTrial                      % Preallocated storage structure for per-trial info
    preallocSize                    % Size of arrays to preallocate
  end
  
  %------- Public data
  properties (SetAccess = protected, Transient)
    logFile                         % Log file that is being written to
    trialData                       % Data to be logged per trial
    savePerNTrials                  % Log backup frequency

    writeIndex                      % Index that current trial will be written into
    writeCounter                    % Number of trials elapsed after last write, for saving to disk
    
    trialEnded                      % >=1 if logEnd() has been called for the current trial but before the next logStart()
  end
  
  properties (SetAccess = protected)
    session                         % Schedule info and list of trial blocks run during this session
    currentTrial                    % The trial being currently recorded into
    currentIt                       % The trial time index being currently recorded into
  end

  %________________________________________________________________________
  methods

    %----- Structure version to store an object of this class to disk
    function frozen = saveobj(obj)
      % Use class metadata to determine what properties to save
      metadata      = metaclass(obj);
      
      % Store all mutable and non-transient data
      for iProp = 1:numel(metadata.PropertyList)
        property    = metadata.PropertyList(iProp);
        if ~property.Transient && ~property.Constant
          frozen.(property.Name)  = obj.(property.Name);
        end
      end
    end
    
    %----- Constructor
    function obj = ExperimentLogMin(logPath)

      obj.preallocSize      = ExperimentLogMin.DEFAULT_PREALLOCSIZE;
      obj.savePerNTrials      = 1;
      obj.writeCounter        = 0;
      
      %Logfile path, C:\Data\USERID\SUBJECTID\DATE_session
      obj.logFile             = fullfile(obj.DEFAULT_PATH, logPath);
      
      % Data automatically collected from ViRMEn
      obj.trialInfo.block     = uint32(0);
      obj.trialInfo.trial     = uint32(0);
      obj.trialInfo.viStart   = uint32(0);
      obj.trialInfo.start     = nan;
      obj.trialInfo.position  = ExperimentLogMin.POSITION_SAMPLE;
      obj.trialInfo.velocity  = ExperimentLogMin.VELOCITY_SAMPLE;
      obj.trialInfo.sensorDots= ExperimentLogMin.SENSORDOTS_SAMPLE;
      obj.trialInfo.collision = false(0);
      obj.trialInfo.time      = nan(0);
      obj.trialInfo.iterations= uint32(0);
      obj.trialInfo.duration  = 0;
      
      % Preallocated storage structure for logging current trial
      obj.emptyTrial          = obj.trialInfo;
      for field = ExperimentLogMin.PREALLOCATED_FIELDS
        if islogical(obj.emptyTrial.(field{:}))
          obj.emptyTrial.(field{:})                         ...
              = false ( obj.preallocSize                    ...
                      , size(obj.emptyTrial.(field{:}),2)   ...
                      );
        else
          obj.emptyTrial.(field{:})                         ...
              = zeros ( obj.preallocSize                    ...
                      , size(obj.emptyTrial.(field{:}),2)   ...
                      , 'like', obj.emptyTrial.(field{:})   ...
                      );
        end
      end
      
      %ALS Create session structure to fill trials in it
      fields_trial  = fieldnames(obj.trialInfo);
      auxcell       = cell(length(fields_trial),1);
      obj.session   = cell2struct(auxcell, fields_trial);
      
      obj.newTrial();
      
    end
    
    % Start a row to save a new trial in the session, 
    function newTrial(obj)
      
      obj.writeIndex            = 0;
      obj.session(end+1).block  = 1;
      obj.session(end).trial    = obj.writeIndex;
        
    end
    
    %----- Writes data stored in this object to disk
    % The argument compact should be set to true (default false) for the
    % final write to disk, as this will strip unfilled trials (not
    % done during the periodic save for speed reasons).
    function log = save(obj, timeNow)

      % If it exists, truncate unused preallocated space for the last trial
      if obj.writeIndex > 0 && ~isnan(obj.currentTrial.duration)
        obj.currentTrial.time(obj.currentIt+1:end,:)        = [];
        obj.currentTrial.sensorDots(obj.currentIt+1:end,:)  = [];
        obj.currentTrial.duration                           = timeNow - obj.currentTrial.start;
        obj.session(end)                                    = obj.currentTrial;  
        obj.newTrial();
      end
            
      makepath(obj.logFile);
      session = obj.session;
      save(obj.logFile, 'session');
      obj.writeCounter          = 0;
      
      % For user's convenience
      log.logFile               = obj.logFile;
      
    end
    
    %----- To be called at the start of each trial to store the time
    function prevTrialDuration = logStart(obj, vr)
      
      % Record duration of the *previous* trial including inter-trial interval 
      if obj.writeIndex > 0
        prevTrialDuration         = vr.timeElapsed - obj.currentTrial.start;
        
        % Have to store the trial info again because extra info can have
        % been logged in the ITI
        obj.currentTrial.time(obj.currentIt+1:end,:)        = [];
        obj.currentTrial.sensorDots(obj.currentIt+1:end,:)  = [];
        obj.currentTrial.duration                           = prevTrialDuration;
      else
        prevTrialDuration         = nan;
      end
              
      % Proceed to next write
      obj.writeIndex              = obj.writeIndex + 1;
      obj.trialEnded              = 0;
      obj.currentTrial            = obj.emptyTrial;
      obj.currentIt               = 0;
      
      % Initialize movement logging
      obj.currentTrial.start      = vr.timeElapsed;
      obj.currentTrial.viStart    = uint32(vr.iterations); 
    end
    
    %----- To be called during behavior to record position and velocity
    function indices = logTick(obj, vr, sensorDots)
      
      % Do nothing if no trial has been started
      if obj.writeIndex < 1
        indices           = [0 0 0];
        return;
      end
      obj.currentIt       = obj.currentIt + 1;

      % These continue to be stored even during the inter-trial interval
      obj.currentTrial.time(obj.currentIt,1)          = vr.timeElapsed - obj.currentTrial.start;
      if nargin > 2 && ~isempty(sensorDots)
        obj.currentTrial.sensorDots(obj.currentIt,:)  = sensorDots(ExperimentLogMin.SENSOR_COORDS);
      end
      
      if obj.trialEnded <= 1      % Should log the final position at end of trial
        obj.currentTrial.position(obj.currentIt,:)    = vr.position(ExperimentLogMin.SPATIAL_COORDS);
        obj.currentTrial.velocity(obj.currentIt,:)    = vr.velocity(ExperimentLogMin.SPATIAL_COORDS);
        obj.currentTrial.collision(obj.currentIt,1)   = vr.collision;
        if obj.trialEnded == 1
          obj.trialEnded  = obj.trialEnded + 1;
        end
      end
      
      indices             = [numel(obj.session), obj.writeIndex, obj.currentIt];
        
    end

    %----- To be called at the end of each trial to store per-trial data
    function logEnd(obj)

      % Mark end of trial (before inter-trial-interval)
      obj.trialEnded    = 1;
      obj.currentTrial.iterations = obj.currentIt + 1;    % Last point
      
      % The following variables are truncated before ITI
      obj.currentTrial.position(obj.currentTrial.iterations+1:end,:)  = [];
      obj.currentTrial.velocity(obj.currentTrial.iterations+1:end,:)  = [];
      obj.currentTrial.collision(obj.currentTrial.iterations+1:end,:) = [];
      
    end
    
    function trial = getTrialSendComm(obj)
        % Get trial to send by tcp at the end of trial
        
          % Get trial sample
          trial = ExperimentLogMin.TRAIL_COMM_SAMPLE;
          % Which fields to copy and what size
          fields = fieldnames(trial);
          size_trial = size(obj.currentTrial.position,1) -1;
          %Form new structure
          for i=1:length(fields)
            trial.(fields{i}) = obj.currentTrial.fields(size_trial, :);
          end
    end
    
    %----- To be called at the end of each trial to handle blocking input
    function logExtras(obj, vr)
      
      % Do nothing if no trial is currently being logged
      if obj.writeIndex < 1
        return;
      end

      % Duration is saved in case there is no next trial
      obj.currentTrial.duration = vr.timeElapsed - obj.currentTrial.start;

      % If a specified number of trials has elapsed, write to disk
      obj.writeCounter    = obj.writeCounter + 1;
      if obj.writeCounter >= obj.savePerNTrials
        obj.save(vr.timeElapsed);
      end

    end
    
    %----- Returns the relative iteration number such that the start of
    %      the current trial corresponds to 1
    function iterNumber = iterationStamp(obj)
      iterNumber    = obj.currentIt;
    end
    
    %----- Returns the start time of the current trial
    function start = trialStart(obj)
      start   = obj.currentTrial.start;
    end
    
    %----- Returns the length of the trial (so far, and not including
    %      inter-trial interval)
    function length = trialLength(obj)
      length  = obj.currentTrial.time(min( end, size(obj.currentTrial.position,1) ));
    end
    
    %----- Compute the total distance logged
    function distance = distanceTraveled(obj)
      if obj.currentIt > 0 && ~isempty(obj.currentTrial)
        displacement  = diff(obj.currentTrial.position(1:obj.currentIt,1:2), 1);
        distance      = sum( sqrt(sum(displacement.^2, 2)) );
      else
        distance      = 0;
      end
    end
    
  end
  
end
