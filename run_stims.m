% Script for running stimulus from struct array 'params'.
% 
% How is different from 'runme' or 'runjuyoung'?
%   1. stimuli as struct array, not cell array.
%   2. create today's directory
%
% Replay of naturalscenes? Excute function 'replay'
    commandwindow
    %%
    addpath('jsonlab/')
    addpath('utils/')
    addpath('functions/')
    addpath('HelperFunctions/')
    %%
    % turn the `debug` flag on when testing
    if ~exist('debug_exp', 'var') == 1
        debug_exp = false;
    end
    
    %%
    try
      
      if ~exist('params', 'var')
        error('Var ''params'' should be defined at WorkSpace');
      end
      
      % id for FOV or Exp.
      loc_id = input(['\nNEW EXPERIMENT: ', ex_title, '\nFOV or Loc name? (e.g. 1 or 2 ..) ']);
      if isempty(loc_id)
          loc_id=999;
      end
      [params(:).name] = deal(['loc',num2str(loc_id), '_', ex_title]);  
        
      % Construct an experimental structure array
      ex = initexptstruct(debug_exp);

      % Initialize the keyboard
      ex = initkb(ex);
      
      % 'params' in workspace
      stimuli = params;
      if isfield(params, 'name')
          str_name = params(1).name;
      else
          str_name = '';
      end
      
       %stimuli = loadjson(fullfile(basedir, 'config.json'));
      
      % today's directory. Create if it doesn't exist for ex history log.
      basedir = fullfile('logs/', ex.today);
      if exist(basedir,'dir') ==0
          mkdir(basedir);
      end
        
      % bg color
      ex.disp.bgcol = 0; % default will be gray.
      
      % Initalize the visual display w/ offset position
      ex = initdisp(ex, 1500, -100);

      % wait for trigger
      ex = waitForTrigger(ex);
      %
      t1 = clock;
      
      % Run the stimuli
      for stimidx = 1:length(stimuli)

        % get the function name for this stimulus
        ex.stim{stimidx}.function = stimuli(stimidx).function;

        % get the user-specified parameters
        ex.stim{stimidx}.params = rmfield(stimuli(stimidx), 'function');
        
        % run this stimulus
        if strcmp(ex.stim{stimidx}.function, 'naturalmovie2')
            if ~exist('movies', 'var')
                movies = []; % should be cell array?
            end
            eval(['ex = ' ex.stim{stimidx}.function '(ex, false, movies);']);
        else
            eval(['ex = ' ex.stim{stimidx}.function '(ex, false);']);
        end


        % intermediate screen btw functions
        if stimidx < length(stimuli)
            %ex = interleavedscreen(ex, stimidx);
        end

      end

      % Check for ESC keypress during the experiment
      ex = checkesc(ex) % if ESC pressed, throws MEception. Don't save. 
      
      %
      ex.t_end = datestr(now, 'HH:MM:SS');
      ex.duration_secs = etime(clock, t1);
      
      % Close windows and textures, clean up
      endexpt();

      if ~debug_exp

        % Save the experimental metadata
        savejson('', ex, fullfile(basedir, [datestr(now, 'HH_MM_SS'), '_ex_', str_name,'.json']));
        save(fullfile(basedir, [datestr(now, 'HH_MM_SS'), '_ex_', str_name,'.mat']), 'ex');

        % Send results via Pushover
        sendexptresults(ex);

        % commit and push
        %commitStr = sprintf(':checkered_flag: Finished experiment on %s', datestr(now));
        %evalc(['!git add -A; git commit -am "' commitStr '"; git push;']);

      end

    % catch errors
    catch my_error  
      % store the error
      ex.my_error = my_error;
     
      % display the error
      disp(my_error);
      struct2table(rmfield(ex.my_error.stack,'file'))
      
      %  
      % Close windows and textures, clean up
      endexpt();

      % Send results via Pushover
      if ~debug_exp
        %sendexptresults(ex);
        %savejson('', ex, fullfile(basedir, ['stopped_', datestr(now, 'HH_MM_SS'), '_expt__', str_name,'.json']));
        save(fullfile(basedir, ['stopped_', datestr(now, 'HH_MM_SS'), '_exlog_', str_name, '.mat']), 'ex');
      end

    end
