function [pixelsX] = PIXELS_PER_100_MICRONS(rig_Name)
    % -- Pablo
    % Return how many pixels are equivalent to 100 microns on the retina.
    % This is done by measuring the square size that matches a known object
    % on the retinal plane. Currently I'm using the Low Density MEA that
    % measures from side to side ~710um (7 spaces of 100um + 10um
    % contacts). By overlaying a square of exactly the same size as the low
    % density MEA the computation is performed.
    % 
    % --1013 2015 Juyoung
    % will depend on two factors: 1. display resolution, 2. imaging
    % magnification.
    % Add the imaging parameter.

    %p=ParseInput(varargin{:});
    
    if nargin < 1
        rig_Name = '2P_new_rig_Olympus_4x';
    end
    
    % 
    [width height] = Screen('WindowSize', max(Screen('Screens')));
    
    switch rig_Name
        case 'D239rig'
            switch width
                case 640
                    pixelsX = 12;
                case 800
                    pixelsX = 14;
                case 1024
                    pixelsX = 17;
                case 1280
                    pixelsX = 22;
                case 1440
                    pixelsX = 25;
                case 1680
                    pixelsX = 30;
                otherwise
                    pixelsX = 17;
                    disp('[PIXELS_PER_100_MICRONS] Current display setting is not defined. 17 pixels were assumed. Execute Screen(''WindowSize'',0) to learn your monitor''s resolution');
            end
        case '2P_rig_Leica_25x'
            pixelsX = 50;
        case '2P_rig_Nikon_10x'     
            pixelsX = 20;
        case '2P_new_rig_Olympus_10x'
            pixelsX = 11.7; % 1 px ~ 8.485 um
            %pixelsX = 20; % 1 px ~ 8.485 um
        case '2P_new_rig_Olympus_4x'
            pixelsX = 4.7; % 1 px ~ 21.2 um
        case 'test'    
            pixelsX = 4.7;
    end
    fprintf('screen size [width]: %d, imaged by %s, 100 um = %d pixels\n', width, rig_Name, pixelsX);       
end

% function p =  ParseInput(varargin)
%     p  = inputParser;   % Create an instance of the inputParser class.
%     
%     p.addParameter('imaging', '2P_new_rig_Olympus_4x', @(x) strcmp(x,'D239rig') || ...
%         strcmp(x,'2P_rig_Nikon_10x') || strcmp(x,'2P_rig_Leica_25x') || ...
%         strcmp(x,'2P_new_rig_Olympus_10x') || strcmp(x,'2P_new_rig_Olympus_4x') || ...
%         strcmp(x,'test'));
%     
%     % p.addParameter('objective', '2P_rig_Leica_25x', @(x) ischar(x));
%     %
%     p.parse(varargin{:});
% end
