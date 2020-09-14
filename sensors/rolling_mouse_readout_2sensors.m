% rolling_mouse_readout()
% Reads out change in mouse x/y position from a microcontroller,
% creates a rolling plot. Uses MouseReader class.

% Ver. 0.2.0, 2014-06-02

function [] = rolling_mouse_readout_2sensors()

    % --------------------
    % parameters
    SERIAL_PORT = RigParameters.arduinoPort; % serial port of microcontroller
    NBUF = 10000; % time range to plot (number of samples)

    
    % --------------------
    % main function

    % create mouse reader object
%     m = MouseReader_2sensors(SERIAL_PORT);
%     cleanupObj1 = onCleanup(@() delete(m));
    arduinoReader('init', 'COM6');
    cleanupObj1 = onCleanup(@() arduinoReader('end'));
        % call mouse reader destructor
        % if this function exits for any reason

    % create plot: x/y mouse displacement vs. time
    [hf, hdF, hdY, hdy, hdx] = create_plot();

    cleanupObj2 = onCleanup(@() close_figure(hf));

        % close figure on exit
    
    % enter main loop: read and plot mouse displacement
    main_loop(hdF, hdY, hdy, hdx);
    
    
    % --------------------
    % creates plot: x/y mouse displacement vs. time
    % returns line object handle for each plot
    function [ hf, hdF, hdA , hdy, hdx] = create_plot()
        % hf = figure handle
        % hx, hy = lineseries object handles
        % for plotting x/y displacement v. time
        
        hf = figure('Units', 'normalized', 'Position', [0 0 1 1]);
        set(gcf, 'Name', 'Mouse displacement vs. time');
        
        args = {'YGrid', 'on', 'YLim', [-200 200]};

        subplot(4, 1, 1);
        hdF = plot(nan, nan);
        set(gca, args{:});
        title('F (front sensor)');
        ylabel('\DeltaF (dots)');

        subplot(4, 1, 2);
        hdA = plot(nan, nan);
        set(gca, args{:});
        title('A (front sensor)');
        xlabel('Time (s)');
        ylabel('\DeltaA (dots)');
        
        subplot(4, 1, 3);
        hdy = plot(nan, nan);
        set(gca, args{:});
        title('Y (bottom sensor)');
        ylabel('\DeltaY (dots)');

        subplot(4, 1, 4);
        hdx = plot(nan, nan);
        set(gca, args{:});
        title('X (bottom sensor)');
        xlabel('Time (s)');
        ylabel('\DeltaX (dots)');

        drawnow;
    end


    % --------------------
    % main loop
    % reads and plots mouse displacement
    function [] = main_loop(hdF, hdA, hdy, hdx)
        % m = MouseReader object
        % hx, hy = lineseries object handles
        % for plotting x/y displacement vs. time
        
        % store time (s) and x/y mouse displacement (dots)
        % in circular buffers
        buf_t = zeros(NBUF, 1);
        buf_dF = zeros(NBUF, 1);
        buf_dA = zeros(NBUF, 1);
        buf_dy = zeros(NBUF, 1);
        buf_dx = zeros(NBUF, 1);
        ptr = 1; % next buffer index to update
        
        % loop
        % exit occurs if user closes figure or presses ctrl-c
        tic;
        ctr = 0; % loop counter
        arduinoReader('poll', 0);
        while ishandle(hdF)
            ctr = ctr + 1;
            
            % measure time since beginning
            t = toc;
            
            % read mouse displacement since previous call
%             m.poll_mouse();
%             [dF, dA, dy, dx] = m.get_xy_change();
            [dF, dA, dy, dx, at, nrep, polli] = arduinoReader('get');
            arduinoReader('poll', ctr);

            % update circular buffers
            buf_t(ptr) = t;
            buf_dF(ptr) = dF;
            buf_dA(ptr) = dA;
            ptr = mod(ptr, NBUF) + 1;

            % unwrap circular buffers for plotting
            tplot = [buf_t(ptr : end); buf_t(1 : ptr - 1)];
            tplot = tplot - tplot(1);
            dFplot = [buf_dF(ptr : end); buf_dF(1 : ptr - 1)];
            dAplot = [buf_dA(ptr : end); buf_dA(1 : ptr - 1)];
            
            % update plot
            try
                set(hdF, 'XData', tplot, 'YData', dFplot);
                set(hdA, 'XData', tplot, 'YData', dAplot);
                drawnow;
            % return if plot has been closed
            catch
                return;
            end
            
            % freeze x axis limits once we've filled buffer
            if ctr == NBUF
                xl = [tplot(1), tplot(end)];
                set(get(hdF, 'parent'), 'xlim', xl);
                set(get(hdA, 'parent'), 'xlim', xl);
            end
            
            %2nd plot
%                         m.poll_mouse();
%             [delta_x, delta_y] = m.get_xy_change();

            % update circular buffers
    
            buf_dy(ptr) = dy;
            buf_dx(ptr) = dx;
      

            % unwrap circular buffers for plotting
   
    
            dyplot = [buf_dy(ptr : end); buf_dy(1 : ptr - 1)];
            dxplot = [buf_dx(ptr : end); buf_dx(1 : ptr - 1)];
            
            % update plot
            try
                set(hdy, 'XData', tplot, 'YData', dyplot);
                set(hdx, 'XData', tplot, 'YData', dxplot);
                drawnow;
            % return if plot has been closed
            catch
                return;
            end
            
            % freeze x axis limits once we've filled buffer
            if ctr == NBUF
                xl = [tplot(1), tplot(end)];
                set(get(hdy, 'parent'), 'xlim', xl);
                set(get(hdx, 'parent'), 'xlim', xl);
            end
            %%%
            
        end % loop
        
        % print refresh rate
        fprintf('FPS = %g\n', 1 ./ mean(diff(tplot)));
    end


    % --------------------
    % close figure w/ handle h
    % encapsulated in a try block in case figure no longer exists
    function [] = close_figure( h )
        try
           % delete(h);
        end
    end

 % --------------------
% functions are nested so that they have access to parameter constants
end