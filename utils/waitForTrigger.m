function ex = waitForTrigger(ex)
%
% FUNCTION ex = waitForTrigger(ex)
%
% The function waitForTrigger deals with the various experiment trigger types.
% It pauses execution of the stimulus, requests that the experimenter press
% the spacebar to arm the trigger, and then either triggers on pressing the 't'
% key or uses WaitForRec, depending on the request.
%
% (c) bnaecker@stanford.edu 24 Jan 2013 

%% text location
xsize = ex.disp.winrect(3);
ysize = ex.disp.winrect(4);
x = 0.45*xsize;
y = 0.42*ysize;

%% arm the trigger

% gray screen only on the dstrect
Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ex.disp.dstrect);

%Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 0 0 0]); % update only red channel??
Screen('DrawText', ex.disp.winptr, 'Press ''spacebar'' to arm trigger ... ', ...
	x, y, ex.disp.pdcolor);

ex.disp.vbl = Screen('Flip', ex.disp.winptr);
while ~ex.key.keycode(ex.key.space) && ~ex.key.keycode(ex.key.esc)
    % (JK comment) Assumption: keycode was initialized as zero vector. 
    % escape the loop by pressing space or esc
	ex = checkkb(ex);
end

%% wait for trigger
if any(strcmp('m', {'m', 'manual'})) % ??? always true?
    Screen('FillRect', ex.disp.winptr, ex.disp.bgcol, ex.disp.dstrect);
	Screen('DrawText', ex.disp.winptr, 'Press ''t'' for experimenter trigger  ... ', ...
		x, y, ex.disp.pdcolor);
	Screen('FillOval', ex.disp.winptr, ex.disp.black, ex.disp.pdrect);
	Screen('Flip', ex.disp.winptr);
	while ~ex.key.keycode(ex.key.t) % escape the loop by pressing 't'
		% KbCheck
        ex = checkkb(ex);
	end
else
	Screen('DrawText', ex.disp.winptr, 'Waiting for recording computer ... ',...
		x, y, ex.disp.pdcolor);
	Screen('FillOval', ex.disp.winptr, ex.disp.black, ex.disp.pdrect);
	Screen('Flip', ex.disp.winptr);
	WaitForRec;
	WaitSecs(0.5);
end

%% hide the cursor to start the experiment
%HideCursor;
%Screen('Blendfunction', ex.disp.winptr, GL_ONE, GL_ZERO, [1 1 1 1]);

end