function [const]=dirSaveFile(const)
% ----------------------------------------------------------------------
% [const]=dirSaveFile(const)
% ----------------------------------------------------------------------
% Goal of the function :
% Make directory and saving files name and fid.
% ----------------------------------------------------------------------
% Input(s) :
% const : struct containing constant configurations
% ----------------------------------------------------------------------
% Output(s):
% const : struct containing constant configurations
% ----------------------------------------------------------------------
% Function created by Martin SZINTE, modified by Vanessa C Morita
% Project :     locVisEndEMexp
% Version :     1.0
% ----------------------------------------------------------------------

% Create data directory 
if ~isdir(sprintf('data/%s/%s/func/',const.sjct,const.session))
    mkdir(sprintf('data/%s/%s/func/',const.sjct,const.session))
end

if const.cond_run_num(const.runNum) > 9
    const.run_txt   =  sprintf('run-%i',const.cond_run_num(const.runNum));
else
    const.run_txt   =  sprintf('run-0%i',const.cond_run_num(const.runNum));
end


% Define directory
const.dat_output_file   =   sprintf('data/%s/%s/func/%s_%s_task-%s%s_%s',const.sjct,const.session,const.sjct,const.session,const.cond2_txt,const.cond1_txt,const.run_txt);

% Eye data
const.eyelink_temp_file =   'XX.edf';
const.eyelink_local_file=   sprintf('%s_eyeData.edf',const.dat_output_file);

% Behavioral data
const.behav_file        =   sprintf('%s_events.tsv',const.dat_output_file);
if const.expStart
    if exist(const.behav_file,'file')
        aswErase = upper(strtrim(input(sprintf('\n\tThis file allready exist, do you want to erase it ? (Y or N): '),'s')));
        if upper(aswErase) == 'N'
            error('Please restart the program with correct input.')
        elseif upper(aswErase) == 'Y'
        else
            error('Incorrect input => Please restart the program with correct input.')
        end
    end
end
const.behav_file_fid    =   fopen(const.behav_file,'w');

% Create additional info directory
if ~isdir(sprintf('data/%s/%s/add/',const.sjct,const.session))
    mkdir(sprintf('data/%s/%s/add/',const.sjct,const.session))
end

% Define directory
const.add_output_file   =   sprintf('data/%s/%s/add/%s_%s_task-%s%s_%s',const.sjct,const.session,const.sjct,const.session,const.cond2_txt,const.cond1_txt,const.run_txt);

% Define .mat saving file
const.mat_file          =   sprintf('%s_matFile.mat',const.add_output_file);

% Direction sequence file
const.task_dir_sequence_file =   sprintf('data/%s/%s/add/%s_task_dir_sequence.mat',const.sjct,const.session,const.sjct);

% Occlusion sizes file
const.task_occlusion_file    =   sprintf('data/%s/%s/add/%s_task_occlusion_size.mat',const.sjct,const.session,const.sjct);

% Log file
if const.writeLogTxt
    const.log_file          =   sprintf('%s_logData.txt',const.add_output_file);
    const.log_file_fid      =   fopen(const.log_file,'w');
end

% Movie file
if const.mkVideo
    if ~isdir(sprintf('others/%s_vid/',const.cond1_txt))
        mkdir(sprintf('others/%s_vid/',const.cond1_txt))
    end
    const.movie_image_file  =   sprintf('others/%s_vid/%s_vid',const.cond1_txt,const.cond1_txt);
    const.movie_file        =   sprintf('others/%s_vid.mp4',const.cond1_txt);
end

end