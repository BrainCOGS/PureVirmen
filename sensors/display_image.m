function [] = display_image()
    % This function opens a serial connection to an Arduino controlling the 
    % ADNS380 optical velocity sensor. The Baudrate in the Arduino sketch must match 
    % wat is used in this function. In the function's main loop,
    % the program sends the 'q' character and gets SQUAL in return; it then sends an 'i' character
    % and gets the latest 30x30 pixel image in return. It then displays the image in a
    % figure with the SQUAL value in text. The main loop runs for 300 iterations. Use
    % Ctrl C to abort earlier. 
    
    % Check for open instruments, close and delete those found
    instr = instrfindall;
    n_instr=size(instr);
    if n_instr>=1
        for m=1:n_instr
            fclose(instr(m));
            delete(instr(m));
        end
    end
    
    % Setup serial port
    s = serial(RigParameters.arduinoPort);
    s.BaudRate = 115200; %make sure arduino code uses same BaudRate
    s.DataBits = 8;
    s.StopBits = 1;
    s.Parity = 'none';
    s.Timeout = 1;
    s.inputbuffersize=1000;
    fopen(s);

    cleanupObj1 = onCleanup(@() close_serial(s));

    % if this function exits for any reason, get rid of serial obj
    
    f = figure;
    
    cleanupObj2 = onCleanup(@() close_figure(f));
    
    % if this function exits for any reason, get rid of figure
   
    im=zeros(30,30);
    pause(1); % provides time to open the serial port
    
    % main loop 
    for n=1:1:5000
        fprintf(s,'q'); % Send command to return SQUAL
        while s.BytesAvailable < 1
        end
        squal = fread(s,s.BytesAvailable,'uint8');
        fprintf(s,'i'); % Send command to return image
        pause(0.2);

        while s.BytesAvailable < 900
        end

            out = fread(s,s.BytesAvailable,'uint8');



            for i=1:1:30
                for j=1:1:30
                    im(i,j)=out(((i-1)*30)+j)-128; %remove bit 7
                end
            end
            im(1,1)=im(1,1)-64; %remove bit 6 from frame start pixel

            imagesc(im);
            axis image;
            qstr = sprintf('%s%d','SQUAL = ',squal);
            text(2,2, qstr , 'color', 'red','FontSize', 18);

            colormap(gray);


    end


    fclose(s);
    delete(s);
    clear s;

    function close_serial(s)
        try
            fclose(s);
            delete(s);
            clear s;
        end
    end
    
    function close_figure(f)
        try
            close(f);
        end
    end

    end

