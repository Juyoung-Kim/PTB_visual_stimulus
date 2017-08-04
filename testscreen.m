function testscreen(debug, modulateColor)

if nargin == 0 
    debug =1;
    modulateColor =[255 255 255];
elseif nargin == 1
    modulateColor =[255 255 255];
end

%modulateColor = [0, 255, 0]
%modulateColor = [0, 0, 255]

commandwindow
addpath('HelperFunctions/')

screen = InitScreen(debug);
waitframes = 1;

    boxL_um = 50; %unit: um
    bar_width = 3; % # boxes.
    boxL = Pixel_for_Micron(boxL_um);  %um to pixels
    disp(['Pixel N for ', num2str(boxL_um), 'um =  ', num2str(boxL), ' px']);
    disp(['Pixel N for ', num2str(100), 'um =  ', num2str(PIXELS_PER_100_MICRONS), ' px']);
    
    N = 31; % determines the stim size
    stimsize = boxL*N;
    % 3-2. MEA Box (150um = MEA length = 30 * 5)
    boxL_ref = 7*PIXELS_PER_100_MICRONS;
    
 % Define the obj Destination Rectangle
objRect = RectForScreen(screen,stimsize,stimsize,0,0);

 for i=1:2
    Screen('FillRect', screen.w, 0.5*modulateColor);
    texMatrix = ( rand(N, N)>.5)*2*screen.gray;

    % 1. random texture pointer
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    % display last texture
    Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, modulateColor); % globalalpha default = 1, but ignored when modulateColor is specified.
    Screen('FillOval', screen.w, screen.white, DefinePD);
    Screen('Flip', screen.w, 0);
    % pause until Keyboard pressed
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    % 27 is 'esc'
    if YorN==27, break; end;
    
    %
    % 2. checker
    %
    %Screen('FillRect', screen.w, screen.gray);
    [x, y] = meshgrid(1:N, 1:N);
    texMatrix = mod(x+y,2)*2*screen.gray;
    % texture pointer
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    % display last texture
    Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, modulateColor);
    Screen('FillOval', screen.w, screen.white, DefinePD);
     %Screen('DrawTexture', windowPointer, texturePointer [,sourceRect]
    %[,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [,
    %modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % 3-1. One Box (0 intensity)
    box =  RectForScreen(screen,boxL,boxL,0, 0);
    Screen('FillRect', screen.w, 0.5*modulateColor);
    Screen('FillRect', screen.w, 0, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % 3-2. MEA Box (0 intensity)
    box =  RectForScreen(screen, boxL_ref, boxL_ref, 0, 0);
    Screen('FillRect', screen.w, 0.5*modulateColor);
    Screen('FillRect', screen.w, 0, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end;
    
    % Stim area (0 intensity outside of the stim area)
    box =  RectForScreen(screen,stimsize,stimsize,0, 0);
    Screen('FillRect', screen.w, 0);
    Screen('FillRect', screen.w, modulateColor, box);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end
    
    % black screen
    Screen('FillRect', screen.w, 0);
    Screen('Flip', screen.w, 0);
    KbWait(-1, 2); [~, ~, c]=KbCheck;  YorN=find(c);
    if YorN==27, break; end
    
    % moving bar?
    % 2*N+1 texture with a bar at the center. Draw a subpart
    texMatrix = ones(N,2*N+1);
    texMatrix(:, N+1) = 0;
    objTex  = Screen('MakeTexture', screen.w, texMatrix);
    
    shiftperframe = 1;% in pixels 
    n_frames = round(stimsize/shiftperframe);
    
    for i = 1:n_frames
        % Shift the grating by "shiftperframe" pixels per frame:
        xoffset = mod(i*shiftperframe, N);
        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture:
        %srcRect=[xoffset 0 xoffset + visiblesize visiblesize];
        
        Screen('FillRect', screen.w, 0.5*modulateColor);
        Screen('DrawTexture', screen.w, objTex, [], objRect, 0, 0, 1, modulateColor);
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        %vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * screen.ifi);
    end
    
    
end

Screen('CloseAll');

end