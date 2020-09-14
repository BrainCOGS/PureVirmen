%% Interface between the Arduino microcontroller with one optical sensor and Matlab. 
%
% This class reads the data sent from the Arduino asynchronously over a USB serial protocol. The
% Arduino continuously routes information from the optical sensor to the serial port.
% MouseReader_1sensor accumulates data from the serial port into its internal buffer. When
% get_xy_change() is called on the object, the values in the buffer are returned and the buffer is
% cleared.
%
% For logging purposes, the last values that get_xy_change() has returned to the user are stored in
% the last_displacement class property.
%
classdef MouseReader_1sensor < handle

	% constants
	properties (Access = private, Constant = true)

		% serial port parameters
		BAUD_RATE = 250000; % speed (bits/s)
		DATA_BITS = 8; % number of data bits
		STOP_BITS = 1; % number of stop bits
		PARITY = 'none'; % parity
		TIMEOUT = 1; % serial read/write times out after this long (s)

		% mouse readout protocol parametes
		REQ_CHAR = 'm'; % request character
			% send this character to request mouse displacement
		TERMINATOR = 'LF'; % terminator character
			% 'LF' == line feed (i.e. newline)
		FORMAT_STR = '%d;%d'; % format string for strread()
			% used for parsing mouse displacement replies from microcontroller
		% mouse displacement reported as string:
		% <delta_x><separator><delta_y><terminator>

	end % constants


	properties (Access = private)

		% change in mouse x/y position since get_xy_change() last called
        % units are mouse sensor 'dots'
		delta_x = 0;
		delta_y = 0;

 		% serial port object
		serial_port;

	end % properties

	properties (SetAccess = protected)

    % last values that get_xy_change() has returned to the user
		last_displacement = [0, 0];

	end % properties

    
	methods

		% constructor
		function [ obj ] = MouseReader_1sensor( port_name )

			% delta_x/y already initialized to 0

			% create serial port object
			obj.serial_port = serial(port_name);
			obj.serial_port.BaudRate = obj.BAUD_RATE;
			obj.serial_port.Terminator = obj.TERMINATOR;
			obj.serial_port.DataBits = obj.DATA_BITS;
			obj.serial_port.StopBits = obj.STOP_BITS;
			obj.serial_port.Parity = obj.PARITY;
			obj.serial_port.Timeout = obj.TIMEOUT;

			% use continuous mode for asynchronous reads. continuously reads
			% any serial input into buffer (should already be set by default)
			obj.serial_port.ReadAsyncMode = 'continuous';

			% setup callback function to handle microcontroller replies to
			% polling requests
			obj.serial_port.BytesAvailableFcnMode = 'terminator';
			obj.serial_port.BytesAvailableFcn = ...
				@(cb_obj, cb_event) obj.update_delta_xy();
			% obj.update_delta_xy() will be called whenever terminator
			% character is detected in input buffer
			
			% adding this callback creates a reference to obj. when obj
			% goes out of scope, this reference continues to exist, so
			% obj's destructor will never be called automatically. must
			% call it manually.

			% open serial port
			fopen(obj.serial_port);
			pause(0.5);
      
		end % constructor


		% destructor
		function [] = delete( obj )
			try % catch all exceptions
                % stop asynchronous reads/writes
                stopasync(obj.serial_port);
                % close and delete serial port object
				fclose(obj.serial_port);
				delete(obj.serial_port);
			end
		end % destructor

		% send polling request to microcontroller
        % reply will be handled by serial input callback function
        % this function doesn't return anything or change object state
		function [] = poll_mouse( obj )
			%fprintf('poll_mouse\n');
            
            % try sending polling request character to microcontroller
            try
                fprintf(obj.serial_port, '%c', obj.REQ_CHAR, 'async');
            catch exception
                % do nothing if we haven't finished sending the
                % previous request
                if strcmp( ...
                    exception.identifier, ...
                    'MATLAB:serial:fprintf:opfailed' ...
                )
                else
                    rethrow(exception);
                end
            end
        end % poll_mouse()

        
        % returns the change in mouse x/y position
        % since this function was last called
		function [ delta_x, delta_y ] = get_xy_change( obj )
			delta_x = obj.delta_x;
			delta_y = obj.delta_y;
			obj.last_displacement = [delta_x, delta_y];
			obj.delta_x = 0;
			obj.delta_y = 0;
        end % get_xy_change

	end % public methods
    
    
    methods (Access = private)
        
        % update mouse displacement values
		% called automatically by callback function when terminator character
		% detected in serial input (i.e. microncontroller reply to polling
        % request has been received)
		function [] = update_delta_xy( obj )

			% read input string (up to terminator character) from serial
            % input buffer
			str = fscanf(obj.serial_port);

			% parse input string
			% add reported x/y displacement to current displacement values
			% leave displacement values alone if anything unexpected happens
			try
				[my_delta_x, my_delta_y] = strread(str, obj.FORMAT_STR);
				if ~isempty(my_delta_x) && ~isempty(my_delta_y);
					obj.delta_x = obj.delta_x + my_delta_x;
					obj.delta_y = obj.delta_y + my_delta_y;
				end
			end
		end % update_delta_xy()

    end % private methods
end % classdef
