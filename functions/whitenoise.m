function ex = whitenoise(ex, replay)
%
% ex = whitenoise(ex, replay)
%
% Required parameters:
%   length : float (length of the experiment in minutes)
%   framerate : float (rough framerate, in Hz)
%   ndims : [int, int] (dimensions of the stimulus)
%   dist: 'gaussian' or 'binary'
%
% Optional parameters:
%   seed : int (for the random number generator. Default: 0)
%
% Runs a receptive field mapping stimulus

  if replay

    % load experiment properties
    numframes = ex.numframes;
    me = ex.params;

    % set the random seed
    rs = getrng(me.seed);

  else

    % shortcut for parameters
    me = ex.stim{end}.params;
    
    % initialize the VBL timestamp
    vbl = GetSecs();

    % initialize random seed
    if isfield(me, 'seed')
      rs = getrng(me.seed);
    else
      rs = getrng();
    end
    ex.stim{end}.seed = rs.Seed;
    
    if ~isfield(me, 'dist')
        me.dist = 'gaussian';
    end
    
    if ~isfield(me, 'contrast')
        me.contrast = 0.35;
    end

    % compute flip times from the desired frame rate and length
    if me.framerate > ex.disp.frate
        error('Your monitor does not support a frame rate higher than %i Hz', ex.disp.frate);
    end
    flipsPerFrame = round(ex.disp.frate / me.framerate);
    ex.stim{end}.framerate = 1 / (flipsPerFrame * ex.disp.ifi);
    flipint = ex.disp.ifi * (flipsPerFrame - 0.125);
    pd_period = round(ex.stim{end}.framerate); % every second.

    % store the number of frames
    numframes = ceil((me.length * 60) * ex.stim{end}.framerate);
    ex.stim{end}.numframes = numframes;
    
    % store timestamps
    ex.stim{end}.timestamps = zeros(ex.stim{end}.numframes, 1);
    
    % Make HiDens masking texture
    %ex = get_hidens_mask(ex);

  end
  
  % ndims of frame
  %Ndims = ndims(me.ndims);
  Ndims = size(me.ndims, 2);
  
  % Adjust dst rect to integer multiplcations of ndims
    L = ex.disp.aperturesize;
    % # of pixels in display for 1 pixel in stimulus frame.
    % isotropic pixel size (integer) along x and y
    px = min( ceil(L/me.ndims(2)), ceil(L/me.ndims(1)) );  
    % Define dst rect as integer multiples of the frame size.
    Lx = px * me.ndims(2);
    Ly = px * me.ndims(1);
    % Adjusted L
    L_whitenoise = max(Lx, Ly);
    ex.disp.aperturesize_whitenoise_mm = L_whitenoise * ex.disp.umperpix/1000;
    % dst rect
    dstrect = CenterRectOnPoint(...	
                    [0 0 L_whitenoise L_whitenoise], ...
                    ex.disp.winctr(1)+ex.disp.offset_x, ex.disp.winctr(2)+ex.disp.offset_y); 
    
  
  % write_mask
  c_mask = me.c_mask;
  if ~replay
    Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);
  end
  % weight factor for mean 
  if isfield(me, 'w_mean')
      weight_mean = me.w_mean;
  else
      weight_mean = 1;
  end

  
  
  % loop over frames
  for fi = 1:numframes

    % generate stimulus pixels
    % Gray multiplication will be simpler for 'gaussian dist'
    if strcmp(me.dist, 'gaussian')
      frame = 1 + me.contrast * randn(rs, me.ndims); % not for white, but for gray.
    elseif strcmp(me.dist, 'uniform')
      % this is actually uniformly distributed
      frame = 2 * rand(rs, me.ndims) * me.contrast + (1 - me.contrast);
    elseif strcmp(me.dist, 'binary')
      %frame = floor(2 * rand(rs, me.ndims)) * me.contrast + (1 - me.contrast);
      frame = 2 * me.contrast * (randi(rs, 2, me.ndims)-1) + (1 - me.contrast);
    elseif strcmp(me.dist, 'binary_color')
      frame = floor(2 * rand(rs, [me.ndims, 3])) * me.contrast + (1 - me.contrast);
    else
      error(['Distribution ' me.dist ': not recognized! Must be gaussian or binary.']);
    end
    
    if replay
%       if ndims(frame) == 3
%           h5write(ex.filename, [ex.group '/stim'], uint8(ex.disp.gray * frame), [1, 1, 1, fi], [[me.ndims, 3], 1]);
%       else
          % write the frame to the hdf5 file
          %h5write(ex.filename, [ex.group '/stim'], uint8(ex.disp.gray * frame), [1, 1, fi], [me.ndims, 1]);
          frame = uint8(frame);
          h5write(ex.filename, [ex.group '/stim'], frame, [ones(1, Ndims), fi], [me.ndims, 1]);
    else
        % apply grayvector
        if Ndims < 3
            frame = color_matrix(frame * weight_mean, ex.disp.graycolor); % 1D, 2D -> 3D matrix
            Ndims = 3;
            me.ndims = [me.ndims, 3];
        elseif Ndims == 3
            frame = color_weight(frame * weight_mean, ex.disp.graycolor); %
        else
            error('Too large dims (>3) for whitenoise presentation.');
        end
        frame = uint8(frame);

      % make the texture
      texid = Screen('MakeTexture', ex.disp.winptr, frame);
    
      % draw the texture, then kill it
      Screen('DrawTexture', ex.disp.winptr, texid, [], dstrect, 0, 0);
      Screen('Close', texid);
      
      % Draw HiDens masking texture
      %Screen('DrawTexture', ex.disp.winptr, ex.disp.hidens_mask, [], [], 90);
      
      % update the photodiode with the top left pixel
      if fi == 1
        pd = ex.disp.pd_color;
        pdrect = ex.disp.pdrect;
      elseif mod(fi, pd_period) == 1
        pd = ex.disp.pd_color;
        pdrect = ex.disp.pdrect2;
      else  
        pd = 0;
      end
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 1]);
      Screen('FillOval', ex.disp.winptr, pd, pdrect);
      Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [c_mask 1]);

      % flip onto the scren
      %Screen('DrawingFinished', ex.disp.winptr);
      %vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);
      
      % flip onto the scren
      Screen('DrawingFinished', ex.disp.winptr);
      [vbl, ~, ~, missed] = Screen('Flip', ex.disp.winptr, vbl + flipint);
      if (missed > 0)
            % A negative value means that dead- lines have been satisfied.
            % Positive values indicate a deadline-miss.
            if (fi > 1) && ex.debug == false
                fprintf('(Whitenoise) frame index %d (%.2f sec): flip missed = %f\n', fi, fi/me.framerate, missed);
                ex.disp.missed = ex.disp.missed + 1;
            end
      end

      % save the timestamp
      ex.stim{end}.timestamps(fi) = vbl;

      % check for ESC
      ex = checkkb(ex);
      if ex.key.keycode(ex.key.esc)
        fprintf('ESC pressed. Quitting.\n')
        break;
      end
        
    end

  end
  % pause(2);
end

function C = color_matrix(A, color)
% color as a weight vector, form a 3D color matrix from 2D matrix A.
n_channels = numel(color);

C = zeros([size(A), n_channels]);

for c = 1:n_channels
    C(:,:,c) = color(c) * A(:,:);
end

end

function C = color_weight(A, color)
% color as a weight vector.
    if ndims(A) ~= 3
        error('Input A should have dim 3 color matrix');
    end
    n = numel(color);
    n_channel = size(A, 3);
    if n ~= n_channel
        error('# of color channels should be same for A and color vector');
    end
    C = zeros(size(A));

    for c = 1:n
        C(:,:,c) = color(c) * A(:,:,c);
    end
end
