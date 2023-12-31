function [expDes] = runTrials(scr,const,expDes,my_key)
% ----------------------------------------------------------------------
% [expDes]=runTrials(scr,const,expDes,my_key)
% ----------------------------------------------------------------------
% Goal of the function :
% Draw stimuli of each indivual trial and waiting for inputs
% ----------------------------------------------------------------------
% Input(s) :
% scr : struct containing screen configurations
% const : struct containing constant configurations
% expDes : struct containg experimental design
% my_key : structure containing keyboard configurations
% ----------------------------------------------------------------------
% Output(s):
% resMat : experimental results (see below)
% expDes : struct containing all the variable design configurations.
% ----------------------------------------------------------------------
% Function created by Martin SZINTE, modified by Vanessa Morita
% Project :     locEMexp
% Version :     1.0
% ----------------------------------------------------------------------


for t = 1:const.seq_num
    
    % Write in log/edf
    log_txt                     =   sprintf('sequence %i started at %f\n',t,GetSecs);
    if const.writeLogTxt
        fprintf(const.log_file_fid,log_txt);
    end
    if const.tracker
        Eyelink('message','%s',log_txt);
    end
    
    % Compute and simplify var and rand
    % ---------------------------------

    % trials number in this sequence    
    seq_trials_mat = expDes.expMat(:,9) == t;
    seq_trials     = expDes.expMat(seq_trials_mat,10);
	trials_idx     = expDes.expMat(seq_trials_mat,2);

    % Cond1 : Task
    cond1 = expDes.expMat(seq_trials_mat,3);

    % Var 1 : eye movement type
    var1  = expDes.expMat(seq_trials_mat,4);
    
    % Var 2 : eye movement direction
    var2  = expDes.expMat(seq_trials_mat,5);
    
    % Var 3 : eye movement start position
    var3  = expDes.expMat(seq_trials_mat,6);
    
    % Var 4 : eye movement amplitude
    var4 = expDes.expMat(seq_trials_mat,8);

    if const.checkTrial && const.expStart == 0
        fprintf(1,'\n\n\t========================  SEQ %3.0f ========================\n',t);
        fprintf(1,'\n\tTask                         =\t%s',expDes.txt_cond1{cond1(1)});
        fprintf(1,'\n\tEye movement direction       =\t%s',expDes.txt_var2{var2(1)});
    end

    % wait first trigger in trial beginning
    if t == 1
        % show the iti image
        Screen('FillRect',scr.main,const.background_color);
        targetX = const.fixation_matX(1);
        targetY = const.fixation_matY(1);
        drawEmptyTarget(scr,const,targetX,targetY,const.white);
        Screen('Flip',scr.main);
        
        first_trigger           =   0;
        expDes.mri_band_val     =   my_key.first_val(3);
        while ~first_trigger
            if const.scanner == 0 || const.scannerTest
                first_trigger           =   1;
                mri_band_val            =   -8;
            else
                keyPressed              =   0;
                keyCode                 =   zeros(1,my_key.keyCodeNum);
                for keyb = 1:size(my_key.keyboard_idx,2)
                    [keyP, keyC]            =   KbQueueCheck(my_key.keyboard_idx(keyb));
                    keyPressed              =   keyPressed+keyP;
                    keyCode                 =   keyCode+keyC;
                end
                if const.scanner == 1
                    input_return = [my_key.ni_session2.inputSingleScan,my_key.ni_session1.inputSingleScan];

                    if input_return(my_key.idx_mri_bands) == ~expDes.mri_band_val
                        keyPressed              = 1;
                        keyCode(my_key.mri_tr)  = 1;
                        expDes.mri_band_val     = ~expDes.mri_band_val;
                        mri_band_val            = input_return(my_key.idx_mri_bands);
                    end
                end

                if keyPressed
                    if keyCode(my_key.escape) && const.expStart == 0
                        overDone(const,my_key)
                    elseif keyCode(my_key.mri_tr)
                        first_trigger          =   1;
                    end
                end
            end
        end

        % write in log/edf
        bar_pass_start          =   GetSecs;
        log_txt                 =   sprintf('sequence %i event mri_trigger val = %i at %f',t,mri_band_val,bar_pass_start);
        if const.writeLogTxt
            fprintf(const.log_file_fid,'%s\n',log_txt);
        end
        if const.tracker
            Eyelink('message','%s',log_txt);
        end
        
    end

                
    % Trial loop
    % ----------
    missed_all = [];
    for seq_trial = 1:seq_trials(end)
        
        if const.checkTrial && const.expStart == 0
            fprintf(1,'\n\tEye movement type            =\t%s',expDes.txt_var1{var1(seq_trial)});
            fprintf(1,'\n\tEye movement direction       =\t%s',expDes.txt_var2{var2(seq_trial)});
            
        end
        
        nbf = 0;
        while nbf < const.TR_num

            % flip count
            nbf = nbf + 1;

            % Draw background
            Screen('FillRect',scr.main,const.background_color);

            % draw ref
            if const.checkTrial && const.expStart == 0
                % amplitude ref
                for tAmp = 1:size(const.eyemov_ampVal,2)
                    Screen('FrameOval',scr.main, const.gray, [scr.x_mid - const.eyemov_amp(tAmp)/2, scr.y_mid - const.eyemov_amp(tAmp)/2, scr.x_mid + const.eyemov_amp(tAmp)/2, scr.y_mid + const.eyemov_amp(tAmp)/2])
                end
                text = sprintf('trial %d: %s',t,expDes.txt_var1{var1(seq_trial)});
                Screen('DrawText',scr.main,text,scr.x_mid-50,scr.y_mid-150,const.gray);
            end
            
            % Draw target
            % fixation sequence
            if var2(seq_trial) == 3
                targetX = const.fixation_matX(nbf);
                targetY = const.fixation_matY(nbf);
                drawTarget(scr,const,targetX,targetY,const.white);
            else
                % eye movement sequence
                
                if var1(seq_trial) == 2
                    % pursuit trial
                    if nbf >= 1 && nbf <= size(const.pursuit_matX,1) %const.pursuit_tot_num
                        % get coordinates
                        targetX = const.pursuit_matX(nbf,var2(seq_trial),seq_trial);
                        targetY = const.pursuit_matY(nbf,var2(seq_trial),seq_trial);
                        color   = repmat(const.color_mat(nbf,var2(seq_trial),seq_trial),1,3);
                    end
                    
                    drawTarget(scr,const,targetX,targetY,color);

                else
                    % saccade trial
                    if nbf >= 1 && nbf <= size(const.saccade_matX,1)
                        % get coordinates
                        targetX = const.saccade_matX(nbf,var2(seq_trial),seq_trial);
                        targetY = const.saccade_matY(nbf,var2(seq_trial),seq_trial);
                    end
                    
                    drawTarget(scr,const,targetX,targetY,const.white);
                end
            end

            % Screen flip
            [~,~,~,missed]    =   Screen('Flip',scr.main);
            
            if sign(missed) == 1
                missed_val              =   1;
                missed_all              =   [missed_all;missed,missed_val];
            else
                missed_val              =   0;
                missed_all              =   [missed_all;missed,missed_val];
            end

            % Create movie
            % ------------
            if const.mkVideo
                expDes.vid_num          =   expDes.vid_num + 1;
                image_vid               =   Screen('GetImage', scr.main);
                imwrite(image_vid,sprintf('%s_frame_%i.png',const.movie_image_file,expDes.vid_num))
                open(const.vid_obj);
                writeVideo(const.vid_obj,image_vid);
            end

            % Save trials times
            if nbf == 1
                % trial onset
                log_txt                 =   sprintf('sequence %i trial %i onset at %f',t,seq_trial,GetSecs);
                if const.writeLogTxt
                    fprintf(const.log_file_fid,'%s\n',log_txt);
                end
                if const.tracker
                    Eyelink('message','%s',log_txt);
                end
                expDes.expMat(trials_idx(seq_trial),11) =   GetSecs;
            end
            
            if nbf == const.TR_num
                % trial offset
                log_txt                 =   sprintf('sequence %i trial %i offset at %f',t,seq_trial,GetSecs);
                if const.writeLogTxt
                    fprintf(const.log_file_fid,'%s\n',log_txt);
                end
                if const.tracker
                    Eyelink('message','%s',log_txt);
                end
                expDes.expMat(trials_idx(seq_trial),12)  =   GetSecs;
            end
            
            if nbf == const.saccade_fix_num+1 && var1(seq_trial) == 1
                % saccade onset
                log_txt                 =   sprintf('sequence %i trial %i saccade onset at %f',t,seq_trial,GetSecs);
                if const.writeLogTxt
                    fprintf(const.log_file_fid,'%s\n',log_txt);
                end
                if const.tracker
                    Eyelink('message','%s',log_txt);
                end
            end
            
            if nbf == 1 && var1(seq_trial) == 2
                % pursuit trial onset
                log_txt                 =   sprintf('sequence %i trial %i pursuit onset at %f',t,seq_trial,GetSecs);
                if const.writeLogTxt
                    fprintf(const.log_file_fid,'%s\n',log_txt);
                end
                if const.tracker
                    Eyelink('message','%s',log_txt);
                end
            end

            % Check keyboard
            % --------------
            keyPressed              =   0;
            keyCode                 =   zeros(1,my_key.keyCodeNum);
            for keyb = 1:size(my_key.keyboard_idx,2)
                [keyP, keyC]            =   KbQueueCheck(my_key.keyboard_idx(keyb));
                keyPressed              =   keyPressed+keyP;
                keyCode                 =   keyCode+keyC;
            end

            if const.scanner == 1
                input_return = [my_key.ni_session2.inputSingleScan,my_key.ni_session1.inputSingleScan];

                % mri trigger
                if input_return(my_key.idx_mri_bands) == ~expDes.mri_band_val
                    keyPressed              = 1;
                    keyCode(my_key.mri_tr)  = 1;
                    expDes.mri_band_val     = ~expDes.mri_band_val;
                    mri_band_val            = input_return(my_key.idx_mri_bands);
                end
            end

            if keyPressed
                if keyCode(my_key.mri_tr)
                    % write in log/edf
                    log_txt                 =   sprintf('sequence %i event mri_trigger val = %i at %f',t,mri_band_val,GetSecs);
                    if const.writeLogTxt
                        fprintf(const.log_file_fid,'%s\n',log_txt);
                    end
                    if const.tracker
                        Eyelink('message','%s',log_txt);
                    end
                elseif keyCode(my_key.escape)
                    if const.expStart == 0
                        overDone(const,my_key)
                    end
                end
            end
        end
        
    end

    % Get number of stim and probe played
    %  -----------------------------------
    % write in log/edf
    log_txt                 =   sprintf('sequence %i - %i missed sync on %i frames, %1.1f%% (mean/median delay = %1.1f/%1.1f ms)',...
                                                t,sum(missed_all(:,2)>0),size(missed_all,1),sum(missed_all(:,2)>0)/size(missed_all,1)*100,...
                                                mean(missed_all(missed_all(:,2)==1))*1000,median(missed_all(missed_all(:,2)==1))*1000);
    if const.writeLogTxt
        fprintf(const.log_file_fid,'%s\n',log_txt);
    end
    if const.tracker
        Eyelink('message','%s',log_txt);
    end
    
    % write in log/edf
    log_txt                     =   sprintf('sequence %i stopped at %f',t,GetSecs);
    if const.writeLogTxt
        fprintf(const.log_file_fid,'%s\n',log_txt);
    end
    if const.tracker
        Eyelink('message', '%s',log_txt);
    end
end

end