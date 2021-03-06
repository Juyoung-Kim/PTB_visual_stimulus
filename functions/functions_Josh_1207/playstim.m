function ex = playstim(ex, replay)
%
% ex = naturalmovie(ex, replay)
%
% Required parameters:
%   length : float (length of the experiment in minutes)
%   framerate : float (rough framerate, in Hz)
%   ndims : [int, int] (dimensions of the stimulus)
%   moviedir: string (location of the movies)
%   movext: string (file extension for the movies)
%   jumpevery: int (number of frames to wait before jumping to a new image)
%   jitter: strength of jitter
%
% Optional parameters:
%   seed : int (for the random number generator. Default: 0)
%
% Runs a natural movie from specified natural_movie_frames.mat file

  if replay
    
    % load experiment properties
    numframes = ex.numframes;
    me = ex.params;movie = load(me.moviepath);
    movie_temp = fields(movie);
    movie = movie.(movie_temp{1});
    

    % set the random seed
   

  else
    
    % shorthand for parameters
    me = ex.stim{end}.params;
    
    % load movie
    movie = load(me.moviepath);
    movie_temp = fields(movie);
    
    movie = movie.(movie_temp{1});
    

    % initialize the VBL timestamp
    vbl = GetSecs();

    % compute flip times from the desired frame rate and length
    if me.framerate > ex.disp.frate
        error('Your monitor does not support a frame rate higher than %i Hz', ex.disp.frate);
    end
    
    flipsPerFrame = round(ex.disp.frate / me.framerate);
    ex.stim{end}.framerate = 1 / (flipsPerFrame * ex.disp.ifi);
    flipint = ex.disp.ifi * (flipsPerFrame - 0.25);

    % darken the photodiode
    Screen('FillOval', ex.disp.winptr, 0, ex.disp.pdrect);
    vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);

    % store the number of frames
    numframes = size(movie,3);
    ex.stim{end}.numframes = numframes;
    assignin('base','numframes',numframes);
    % store timestamps
    ex.stim{end}.timestamps = zeros(ex.stim{end}.numframes,1);

  end



  % loop over frames
  
  for fi = 1:numframes
 
    frame = movie(:,:,fi);
    
    if replay
      % write the frame to the hdf5 file
      h5write(ex.filename, [ex.group '/stim'], frame, [1, 1, fi], [me.ndims, 1]);
    else
      % make the texture
      texid = Screen('MakeTexture', ex.disp.winptr, frame);
      % draw the texture, then kill it
      Screen('DrawTexture', ex.disp.winptr, texid, [], ex.disp.dstrect, 0, 0);
      Screen('Close', texid);
      % update the photodiode with the top left pixel on the first frame
      if fi == 1
        pd = ex.disp.white;
%       elseif mod(fi, me.jumpevery) == 1
%         pd = 0.6 * ex.disp.white;
      else
        pd = 0;
      end
      Screen('FillOval', ex.disp.winptr, pd, ex.disp.pdrect);

      % flip onto the scren
      Screen('DrawingFinished', ex.disp.winptr);
      vbl = Screen('Flip', ex.disp.winptr, vbl + flipint);

      % save the timestamp
      ex.stim{end}.timestamps(fi) = vbl;

      % check for ESC
      ex = checkkb(ex);
      if ex.key.keycode(ex.key.esc)
        fprintf('ESC pressed. Quitting.')
        break;
      end

    end

  end
end

function xn = rescale(x)
  xmin = min(x(:));
  xmax = max(x(:));
  xn = (x - xmin) / (xmax - xmin);
end
