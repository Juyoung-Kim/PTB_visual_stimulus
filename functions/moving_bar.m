function moving_bar(varargin)
% Modified from DriftDemo3
%
% 2017 1001 Juyoung Kim
% 

p = ParseInput(varargin{:});
%
bar_width = p.Results.barWidth;
bar_speed = p.Results.barSpeed;
bar_color = p.Results.barColor;
N_repeats = p.Results.N_repeat;

% bar sweep size
visiblesize = 256;        % Size of the grating image. Needs to be a power of two.
%
bar_width = Pixel_for_Micron(bar_width);
speed_in_Pixels = Pixel_for_Micron(bar_speed*1000);


% This script calls Psychtoolbox commands available only in OpenGL-based 
% versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox.
AssertOpenGL;

% Get the list of screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when 
% two monitors are connected the one without the menu bar is used as 
% the stimulus display.  Chosing the display with the highest dislay number is 
% a best guess about where you want the stimulus displayed.  
screens=Screen('Screens');
screenNumber=max(screens);

% Find the color values which correspond to white and black: Usually
% black is always 0 and white 255, but this rule is not true if one of
% the high precision framebuffer modes is enabled via the
% PsychImaging() commmand, so we query the true values via the
% functions WhiteIndex and BlackIndex:
white=WhiteIndex(screenNumber)
black=BlackIndex(screenNumber);

% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
gray=round((white+black)/2);

% This makes sure that on floating point framebuffers we still get a
% well defined gray. It isn't strictly neccessary in this demo:
if gray == white
    gray=white / 2;
end

% Contrast 'inc'rement range for given white and gray values:
inc=white-gray;

% Open a double buffered fullscreen window and draw a gray background 
% to front and back buffers as background clear color:
[w, w_rect] = Screen('OpenWindow',screenNumber, gray);

% Create one single static 1-D grating image.
% We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
% define the whole grating! If the 'srcRect' in the 'Drawtexture' call
% below is "higher" than that (i.e. visibleSize >> 1), the GPU will
% automatically replicate pixel rows. This 1 pixel height saves memory
% and memory bandwith, ie. it is potentially faster on some GPUs.

white_bar = gray + inc*(1:visiblesize <= bar_width);
dark_bar = gray*(1:visiblesize > bar_width);

% Store grating in texture: Set the 'enforcepot' flag to 1 to signal
% Psychtoolbox that we want a special scrollable power-of-two texture:

switch bar_color
    case 'white'
        bartex=Screen('MakeTexture', w, white_bar, [], 1);
    case 'dark'
        bartex=Screen('MakeTexture', w, dark_bar, [], 1);
    otherwise
        
end

% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', w);
waitframes = 1; % max refreash rate
waitduration = waitframes * ifi;
%
shiftperframe= speed_in_Pixels * waitduration;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
vbl=Screen('Flip', w);

% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
%vblendtime = vbl + movieDurationSecs;
xoffset=0;
pd = DefinePD_shift(w);

%
WaitStartKey(w, 'expName', ['Moving bar (', bar_color, ')']);

% first cycle
i_cycle = 1;
Screen('FillOval', w, white, pd);

% Animationloop:
while(i_cycle <= N_repeats)   
   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
   srcRect=[xoffset 0 xoffset + visiblesize visiblesize];

   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
   %Screen('DrawTexture', w, gratingtex, srcRect);
   Screen('DrawTexture', w, bartex, srcRect);
   
   % Flip 'waitframes' monitor refresh intervals after last redraw.
   vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);

   % Abort demo if any key is pressed:
   if KbCheck
      break;
   end;
   
   % Shift the grating by "shiftperframe" pixels per frame:
   xoffset = xoffset - shiftperframe;
   
   if xoffset < -(visiblesize-bar_width)
       
       xoffset = 0; % set to same position
       Screen('FillOval', w, white, pd);
       
       i_cycle = i_cycle +1;
   end
   
end;

% The same commands wich close onscreen and offscreen windows also close
% textures.
sca;

end

function p =  ParseInput(varargin)
    
    p  = inputParser;   % Create an instance of the inputParser class.
    
    addParamValue(p,'N_repeat', 20, @(x)x>=0);
    addParamValue(p,'barWidth', 100, @(x)x>=0);
    addParamValue(p,'barSpeed', 1.4, @(x)x>=0);
    
    addParamValue(p,'barColor', 'dark', @(x) strcmp(x,'dark') || ...
        strcmp(x,'white'));
     
    % Call the parse method of the object to read and validate each argument in the schema:
    p.parse(varargin{:});
    
end


