% Regenerate stimulus frames for an experiment
%
% (c) 2015 Niru Maheswaranathan
% revised by Lane McIntosh
% revised by Juyoung Kim
%
% 04 May 2015 - initial version
% 20 Jun 2018 - File select in given dir
addpath('jsonlab/')
addpath('utils/')
addpath('functions/')

%% load experiment
% dir select
which_expt = input(['Which experiment (yy-mm-dd) would you like to replay (default: ', datestr(now, 'yy-mm-dd'),')? '],'s');
if isempty(which_expt)
    which_expt = datestr(now, 'yy-mm-dd') % today
end
basedir = fullfile('logs/', which_expt);

% file search
files = dir(fullfile(basedir, '*.json'));
num_ex_files = length(files);
if num_ex_files < 1
  error('no ex (mat files) in designated folder');
else 
    for fileidx = 1:num_ex_files
        disp([num2str(fileidx), ': ', files(fileidx).name]); 
    end
end
disp('');

% File select
which_ex  = input('Which ex (json) file would you like to replay? ');
ex_filename  = files(which_ex).name;
ex_replay = loadjson(fullfile(cd, basedir, ex_filename));
ex_filename = strsplit(ex_filename,'.');
ex_filename = ex_filename{1};

%%
% if exist(fullfile(cd, basedir, 'expt.json'), 'file') == 2
%   expt = loadjson(fullfile(cd, basedir, 'expt.json'));
% else
%   error('Could not find expt.json file for today!')
% end

% filename for the hdf5 file
fname = ['stimulus_',ex_filename,'.h5']; %fullfile(expanduser('~/Desktop/'), datestr(now, 'mmddyy'), 'stimulus.h5');
basedir = 'C:\Users\Administrator\Documents\MATLAB\visual_stimulus\logs';
basedir = 'logs';
fname = fullfile(basedir, which_expt, fname)
if exist(fname, 'file')
    delete(fname)
    disp('File deleted..');
end
%% replay experiments
numstim = length(ex_replay.stim);
for stimidx = 1:numstim

      % pull out the function and parameters
      % structure 'stim'
      if numstim == 1
          stim = ex_replay.stim;
      else
          stim = ex_replay.stim{stimidx};
      end
      me = stim.params;
      stim.params.gray = ex_replay.disp.gray;
      fields = fieldnames(me);

      % group name
      disp(['stim id: ', num2str(stimidx)]);
      group = ['/expt', num2str(stimidx)];
      
      if contains(stim.function, 'grayscreen')
          continue;
      end
        
      % Default scale factor for sampling stimulus movie
      if ~isfield(me, 'sampling_scale')
          me.sampling_scale = 1;
      end
      
      % presentation dimention for h5 file creation in advance.
      if ~isfield(me, 'ndims')
          disp('''ndims'' was not defined in ''ex'' struct.');
          me.ndims = [50 50];
      end

      % store the stimulus pixel values
      stim.filename = fname; %fname;
      stim.group = group;
      stim.disp = ex_replay.disp; % for relay. not saved in h5 file. 

      % REPLAY: h5write at stim.filename.
      % check if filename has been used.
      h5create(fname, [group '/stim'], [me.ndims, stim.numframes], 'Datatype', 'uint8');
      
      % pass 'stim' instead of 'ex'.
        if contains(stim.function, 'naturalmovie2')
            eval(['ex = ' stim.function '(stim, true, movies);']);
        else
            eval(['ex = ' stim.function '(stim, true);']);
        end
      
%       if strcmp(stim.function, 'naturalmovie2')
%         h5create(fname, [group '/stim'], [me.ndims, 3, stim.numframes], 'Datatype', 'uint8');
%         %h5create(fname, [group '/stim'], [me.ndims, 3, stim.numframes], 'Datatype', 'uint8');
%         eval(['ex = ' stim.function '(stim, true, movies);']);
%       else
%         h5create(fname, [group '/stim'], [me.ndims, stim.numframes], 'Datatype', 'uint8');
%         eval(['ex = ' stim.function '(stim, true);']);
%       end
      
      % repeat numbers
      if ~isfield(me, 'repeat')
          me.repeat = 1;
      end
      
      % store the timestamps
      h5create(fname, [group '/timestamps'], [stim.numframes, me.repeat]); % [ , num of repeats]
      %h5write(fname, [group '/timestamps'], stim.timestamps - stim.timestamps(1));
      h5write(fname, [group '/timestamps'], stim.timestamps);

      % store metadata
      h5writeatt(fname, group, 'function', stim.function);
      h5writeatt(fname, group, 'framerate', stim.framerate);
      for idx = 1:length(fields)
        h5writeatt(fname, group, fields{idx}, getfield(me, fields{idx}));
      end
end

% group 'disp'
group = '/disp';
h5create(fname, group, [1, 1], 'Datatype', 'uint8');
fields = fieldnames(ex_replay.disp);
for idx = 1:length(fields)
    value = getfield(ex_replay.disp, fields{idx});
    if isnumeric(value)
        h5writeatt(fname, group, fields{idx}, value);
    end
    %disp([fields{idx}, ': done']);
end

h5disp(fname);