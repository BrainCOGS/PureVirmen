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

classdef ExperimentLogVirmen < handle

  %------- Constants
  properties (Constant)
    
    SPATIAL_COORDS  = [1 2 4];      % Columns of vr.position and vr.velocity to store
    SENSOR_COORDS   = 1:5;          % Columns of raw sensor readout to store
%     SENSOR_COORDS   = 1:7;          % Columns of raw sensor readout to store
    SENSOR_DATASIZE = 'int16';      % Data type specifier for raw sensor readout
    
    DEFAULT_PREALLOCSIZE  = 10000   % Default size of arrays to preallocate
    
    DEFAULT_PATH          = 'C:\Data\'
                     
  end
  
  %------- Private data
  properties (Access = protected, Transient)
    trialInfo                       % Storage structure for per-trial info
    emptyTrial                      % Preallocated storage structure for per-trial info
    emptyTrial_prealloc             % Empty trial only formed of preallocated fields (position, velocity, etc)
    preallocSize                    % Size of arrays to preallocate
    fieldInfo                       % Information for each field to be stored by Virmen
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
    function obj = ExperimentLogVirmen(logPath, fieldInfo)

      obj.preallocSize        = ExperimentLogVirmen.DEFAULT_PREALLOCSIZE;
      obj.savePerNTrials      = 1;
      obj.writeCounter        = 0;
      
      %Logfile path, C:\Data\USERID\SUBJECTID\DATE_session
      obj.logFile             = fullfile(obj.DEFAULT_PATH, logPath);
      
      %Which fields are going to be stored by virmen
      %fieldInfo = VirmenBControl.field_definition.TowersTaskFields;
      trial_fields = fieldInfo.trial_fields;
      obj.fieldInfo = trial_fields(trial_fields.virmen_or_bcontrol == 'virmen' | ...
                                   trial_fields.virmen_or_bcontrol == 'both', :);
      
      %Create an empty trial with fieldInfo table
      obj.emptyTrial = struct();
      for i=1:length(obj.fieldInfo.field_name)
          curr_field = obj.fieldInfo.field_name{i};
          curr_value = obj.fieldInfo.default_value{i};
          obj.emptyTrial.(curr_field) = curr_value;
      end
      
      % Preallocated storage structure for logging current trial
      prealloc_fields = obj.fieldInfo{obj.fieldInfo.prealloc_field == 1, 'field_name'};
      obj.emptyTrial_prealloc = struct();
      for i = 1:length(prealloc_fields)
          curr_field = prealloc_fields{i};
        obj.emptyTrial_prealloc.(curr_field) = repmat(obj.emptyTrial.(curr_field),obj.preallocSize, 1);    
      end
      
      %ALS Create session structure to fill trials in it
      %fields_trial  = obj.fieldInfo.field_name;
      %auxcell       = cell(length(fields_trial),1);
      %obj.session   = cell2struct(auxcell, fields_trial);
      
      obj.writeIndex = 0;
      obj.newTrial();
      
    end
    
    % Start a row to save a new trial in the session, 
    function newTrial(obj)
      
      obj.writeIndex            = obj.writeIndex + 1;
        
    end
    
    %----- Writes data stored in this object to disk
    % The argument compact should be set to true (default false) for the
    % final write to disk, as this will strip unfilled trials (not
    % done during the periodic save for speed reasons).
    function log = save(obj)

      % If it exists, truncate unused preallocated space for the last trial
     obj.currentTrial.trial_time(obj.currentIt+1:end,:)   = [];
     obj.currentTrial.sensor_dots(obj.currentIt+1:end,:)  = [];
     %obj.currentTrial.duration                           = timeNow - obj.currentTrial.start;  
     if obj.writeIndex == 1
         obj.session                                      = obj.currentTrial;
     else
         if length(fieldnames(obj.currentTrial)) == length(obj.fieldInfo.field_name)
            obj.session(obj.writeIndex)                      = obj.currentTrial;
         else
             warning('Incomplete trial for saving')
         end
     end
     obj.newTrial();
            
     makepath(obj.logFile);
     session = obj.session;
     save(obj.logFile, 'session');
     obj.writeCounter          = 0;
      
     % For user's convenience
     log.logFile               = obj.logFile;
      
    end
    
    %----- To be called at the start of each trial to store the time
    function logStart(obj, vr)
      
      % Record duration of the *previous* trial including inter-trial interval 
      %if obj.writeIndex > 0
      %  prevTrialDuration         = vr.timeElapsed - obj.currentTrial.start;
        
        % Have to store the trial info again because extra info can have
        % been logged in the ITI
      %  obj.currentTrial.trial_time(obj.currentIt+1:end,:)        = [];
      %  obj.currentTrial.sensor_dots(obj.currentIt+1:end,:)  = [];
      %  obj.currentTrial.duration                           = prevTrialDuration;
      %else
      %  prevTrialDuration         = nan;
      %end
              
      % Proceed to next write
      obj.trialEnded              = 0;
      obj.currentTrial            = obj.emptyTrial_prealloc;
      obj.currentIt               = 0;
      
      % Initialize movement logging
      obj.currentTrial.trial_abs_start = vr.timeElapsed;
      obj.currentTrial.vi_start        = uint32(vr.iterations); 
      obj.currentTrial.trial_idx       = obj.writeIndex;
    end
    
    %----- To be called during behavior to record position and velocity
    function indices = logTick(obj, vr, sensorDots)
      
      % Do nothing if no trial has been started
      if obj.writeIndex < 1 || isempty(obj.currentTrial)
        indices           = [0 0 0];
        return;
      end
      obj.currentIt       = obj.currentIt + 1;

      % These continue to be stored even during the inter-trial interval
      obj.currentTrial.trial_time(obj.currentIt,1)          = vr.timeElapsed - obj.currentTrial.trial_abs_start;
      if nargin > 2 && ~isempty(sensorDots)
        obj.currentTrial.sensor_dots(obj.currentIt,:)  = sensorDots(ExperimentLogVirmen.SENSOR_COORDS);
      end
      
      if obj.trialEnded <= 1      % Should log the final position at end of trial
        obj.currentTrial.position(obj.currentIt,:)    = vr.position(ExperimentLogVirmen.SPATIAL_COORDS);
        obj.currentTrial.velocity(obj.currentIt,:)    = vr.velocity(ExperimentLogVirmen.SPATIAL_COORDS);
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
      obj.currentTrial.position(obj.currentTrial.iterations:end,:)  = [];
      obj.currentTrial.velocity(obj.currentTrial.iterations:end,:)  = [];
      obj.currentTrial.collision(obj.currentTrial.iterations:end,:) = [];
      
    end
    
    function trial = getTrialSendComm(obj)
        % Get trial to send by tcp at the end of trial
        
          % Check if currentTrial has all fields corresponding to Virmen
          field_complete_trial = obj.fieldInfo.field_name;
          fields_curr_trial    = fieldnames(obj.currentTrial);
          
          %If there are missing fields, send a warning and complete trial with default values
          missing_fields = setdiff(field_complete_trial, fields_curr_trial);
          if ~isempty(missing_fields)
              warning(['Next fields were not set to current trial:  ' sprintf([newline '%s'] ,missing_fields{:})])
              obj.currentTrial = cat_struct(obj.currentTrial, obj.emptyTrial);
          end
          
          trial = obj.currentTrial;
          
    end
    
    %----- To be called at the end of each trial to handle blocking input
    function logExtras(obj, vr)
      
      % Do nothing if no trial is currently being logged
      if obj.writeIndex < 1
        return;
      end

      % Duration is saved in case there is no next trial
      %obj.currentTrial.duration = vr.timeElapsed - obj.currentTrial.trial_abs_start;
      %Get missing fields from vr
      
      % cue onset and offset logs
      obj.currentTrial.cue_onset_left     = {vr.cueOnset{Choice.L}};
      obj.currentTrial.cue_onset_right    = {vr.cueOnset{Choice.R}};
      obj.currentTrial.cue_offset_left    = {vr.cueOffset{Choice.L}};
      obj.currentTrial.cue_offset_right   = {vr.cueOffset{Choice.R}};

      % Entry to regions log
      region_table = vr.virmen_structures.regions.region_table;
      obj.currentTrial.i_cue_entry        = region_table{Region2.InCues, 'entry'}; %vr.iCueEntry;
      obj.currentTrial.i_mem_entry        = region_table{Region2.InMemory, 'entry'};
      obj.currentTrial.i_turn_entry       = region_table{Region2.InTurn, 'entry'};
      obj.currentTrial.i_arm_entry        = region_table{Region2.InArms, 'entry'};
      obj.currentTrial.i_blank            = vr.iBlank;
      
      % Distance traveled variables
      obj.currentTrial.maze_length        = vr.mazeLength;
      
      % If a specified number of trials has elapsed, write to disk
      obj.writeCounter    = obj.writeCounter + 1;
      if obj.writeCounter >= obj.savePerNTrials
        obj.save();
      end

    end
    
    %----- Returns the relative iteration number such that the start of
    %      the current trial corresponds to 1
    function iterNumber = iterationStamp(obj)
      iterNumber    = obj.currentIt;
    end
    
    %----- Returns the start time of the current trial
    function start = trialStart(obj)
      start   = obj.currentTrial.trial_abs_start;
    end
    
  end
  
end
