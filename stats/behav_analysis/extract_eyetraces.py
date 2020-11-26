"""
-----------------------------------------------------------------------------------------
extract_eyetraces.py
-----------------------------------------------------------------------------------------
Goal of the script:
Extract eye traces from edf file and arrange them well for later treatment
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: subject number (sub-01)
sys.argv[2]: task (EyeMov)
-----------------------------------------------------------------------------------------
Output(s):
h5 files with loads of data on eye traces across runs
-----------------------------------------------------------------------------------------
To run:
cd /Users/martin/Dropbox/Experiments/pMFexp/stats/
python behav_analysis/extract_eyetraces.py sub-01 EyeMov ses-01
-----------------------------------------------------------------------------------------
"""

# Stop warnings
# -------------
import warnings
warnings.filterwarnings("ignore")

# General imports
# ---------------
import os
import sys
import platform
import re
import numpy as np
import ipdb
import json
import h5py
import scipy.io
deb = ipdb.set_trace

# Get inputs
# ----------
subject = sys.argv[1]
task    = sys.argv[2]
session = sys.argv[3]

# Define analysis parameters
# --------------------------
with open('behavior_settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)

# Get eyelink data
# ----------------
if platform.system() == 'Darwin':
    main_dir = analysis_info['main_dir_mac']
    edf2asc_dir = analysis_info['edf2asc_dir_mac']
    end_file = ''

elif platform.system() == 'Windows':
    main_dir = analysis_info['main_dir_pc']
    edf2asc_dir = analysis_info['edf2asc_dir_win']
    end_file ='.exe'

elif platform.system() == 'Linux':
    main_dir = analysis_info['main_dir_unix']

# Define file list
# ----------------
file_dir = '{exp_dir}/data/{sub}/{ses}'.format(exp_dir = main_dir, sub = subject, ses = session)
list_filename = ['{sub}_{ses}_task-{task}_run-01'.format(sub = subject, ses = session, task = task),
                 '{sub}_{ses}_task-{task}_run-02'.format(sub = subject, ses = session, task = task),]


# Define experiments details
# --------------------------
if subject[-1]=='t':
    num_run = np.arange(0,analysis_info['num_run_t'],1)
else:
    num_run = np.arange(0,analysis_info['num_run'],1)
num_seq = analysis_info['num_seq']
seq_trs = analysis_info['seq_trs']
eye_mov_seq = analysis_info['eye_mov_seq'] # ?
rads = analysis_info['rads']
pursuits_tr = np.arange(0,seq_trs,2) # ?
saccades_tr = np.arange(1,seq_trs,2) # ?

trials_seq = np.array(analysis_info['trials_seq'])
seq_type   = np.array(analysis_info['seq_type'])


mat_seqDir_filename = '{file_dir}/add/{sub}_task_dir_sequence.mat'.format(file_dir = file_dir,sub = subject)
matSeqDir = scipy.io.loadmat(mat_seqDir_filename)
matSeqDir = matSeqDir['dir_sequence'][0][0][0].flatten()
matSeqDir = [1 if x==1 else -1 for x in matSeqDir] # x==1 -> ccw, x==2 -> cw


# Extract data
# -------------
eye_data_runs = []
time_last_run_eye   =   0
time_start_eye = np.zeros((1,len(num_run)))
time_end_eye = np.zeros((1,len(num_run)))
time_start_seq = np.zeros((num_seq,len(num_run)))
time_end_seq = np.zeros((num_seq,len(num_run)))
time_start_trial = np.zeros((seq_trs,num_seq,len(num_run)))
time_end_trial = np.zeros((seq_trs,num_seq,len(num_run)))
for t_run in np.arange(0,len(num_run),1):

    edf_filename = '{file_dir}/func/{filename}_eyeData'.format(file_dir = file_dir,filename = list_filename[t_run])
    mat_filename = '{file_dir}/add/{filename}_matFile.mat'.format(file_dir = file_dir,filename = list_filename[t_run])

    # get .msg and .dat file
    if not os.path.exists('{}.msg'.format(edf_filename)):
        if platform.system() == 'Linux':
            os.system('edf2asc {edf_filename}.edf -e -y'.format(edf_filename = edf_filename))
        else:
            os.system('{edf2asc_dir}/edf2asc{end_file} {edf_filename}.edf -e -y'.format(edf2asc_dir = edf2asc_dir,
                                                                               end_file = end_file,
                                                                               edf_filename = edf_filename))
        os.rename('{}.asc'.format(edf_filename),'{}.msg'.format(edf_filename))

    if not os.path.exists('{}.dat'.format(edf_filename)):
        if platform.system() == 'Linux':
            os.system('edf2asc {edf_filename}.edf -s -miss -1.0 -y'.format(edf_filename = edf_filename))
        else:
            os.system('{edf2asc_dir}/edf2asc{end_file} {edf_filename}.edf -s -miss -1.0 -y'.format( edf2asc_dir = edf2asc_dir,
                                                                                          end_file = end_file,
                                                                                          edf_filename = edf_filename))
        os.rename('{}.asc'.format(edf_filename),'{}.dat'.format(edf_filename))

    # get first and last time pf each run
    msgfid = open('{}.msg'.format(edf_filename))
    first_last_time = False
    first_time = False
    last_time = False
    seq_num = 0
    while not first_last_time:
        line_read = msgfid.readline()
        if not line_read == '':
            la = line_read.split()

        if re.search(r"MSG", line_read):
            if line_read.find('sequence 1 started') != -1 and not first_time:
                time_start_eye[0,t_run] = float(la[1])
                print('first time true')
                first_time = True

            if line_read.find('sequence 9 stopped') != -1 and not last_time:
                time_end_eye[0,t_run] = float(la[1])
                print('last time true')
                last_time = True

            if re.search(r"sequence\s\d+\sstarted", line_read):
                time_start_seq[seq_num,t_run] = float(la[1])
                trial_num = 0

            if re.search(r"sequence\s\d+\sstopped", line_read):
                time_end_seq[seq_num,t_run] = float(la[1])
                print('seq {} finished'.format(seq_num))
                seq_num += 1

            if re.search(r"trial\s\d+\sonset", line_read):
                time_start_trial[trial_num,seq_num,t_run] = float(la[1])

            if re.search(r"trial\s\d+\soffset", line_read):
                time_end_trial[trial_num,seq_num,t_run] = float(la[1])
                trial_num += 1

        if first_time == True and last_time == True:
            first_last_time = True
            msgfid.close()


    # load eye coord data
    eye_dat = np.genfromtxt('{}.dat'.format(edf_filename),usecols=(0, 1, 2))
    eye_data_run = eye_dat[np.logical_and(eye_dat[:,0]>=time_start_eye[0,t_run],eye_dat[:,0]<=time_end_eye[0,t_run])]

    # add run number
    eye_data_run = np.concatenate((eye_data_run,np.ones((eye_data_run.shape[0],1))*(t_run)),axis = 1)
    # col 0 = time
    # col 2 = eye x coord
    # col 3 = eye y coord
    # col 4 = run number

    if re.search(r"Pur", task):
        timeStartSeq = time_start_trial[0,seq_type==1,t_run]
        timeEndSeq   = time_end_trial[29,seq_type==1,t_run] # last TR with pursuit of the seq

        seq_tmp = []
        for idx in range(len(timeStartSeq)):
            data_idx = (eye_data_run[:,0]>=timeStartSeq[idx]) & (eye_data_run[:,0]<=timeEndSeq[idx]) 
            seq  = (idx+1) * np.ones(sum(data_idx)) 
            data = np.c_[ eye_data_run[data_idx,:], seq ]
            
            if idx == 0:
                seq_tmp = data
            else:
                seq_tmp = np.concatenate((seq_tmp,data), axis=0)

        if t_run == 0:
            eye_data_runs = eye_data_run
            eye_data_seqs = seq_tmp
        else:
            eye_data_runs = np.concatenate((eye_data_runs,eye_data_run), axis=0)
            eye_data_seqs = np.concatenate((eye_data_seqs,seq_tmp), axis=0)

        # eye_data_seqs
        # col 0 = time
        # col 1 = eye x coord
        # col 2 = eye y coord
        # col 3 = run number
        # col 4 = seq number
        
    # remove msg and dat
    os.remove('{}.msg'.format(edf_filename))
    os.remove('{}.dat'.format(edf_filename))



# Put nan for blink time
blinkNum = 0
blink_start = False
for tTime in np.arange(0,eye_data_runs.shape[0],1):

    if not blink_start:
        if eye_data_runs[tTime,1] == -1:

            blinkNum += 1
            timeBlinkOnset = eye_data_runs[tTime,0]
            blink_start = True
            if blinkNum == 1:
                blink_onset_offset = np.matrix([timeBlinkOnset,np.nan])
            else:
                blink_onset_offset = np.vstack((blink_onset_offset,[timeBlinkOnset,np.nan]))

    if blink_start:
        if eye_data_runs[tTime,1] != -1:
            timeBlinkOffset = eye_data_runs[tTime,0]
            blink_start = 0
            blink_onset_offset[blinkNum-1,1] = timeBlinkOffset

# nan record around detected blinks
eye_data_runs_nan_blink = np.copy(eye_data_runs)
if re.search(r"Pur", task):
    eye_data_seqs_nan_blink = np.copy(eye_data_seqs)

for tBlink in np.arange(0,blinkNum,1):

    blink_onset_offset[tBlink,0] = blink_onset_offset[tBlink,0]
    blink_onset_offset[tBlink,1] = blink_onset_offset[tBlink,1]

    eye_data_runs_nan_blink[np.logical_and(eye_data_runs_nan_blink[:,0] >= blink_onset_offset[tBlink,0],eye_data_runs_nan_blink[:,0] <= blink_onset_offset[tBlink,1]),1] = np.nan
    eye_data_runs_nan_blink[np.logical_and(eye_data_runs_nan_blink[:,0] >= blink_onset_offset[tBlink,0],eye_data_runs_nan_blink[:,0] <= blink_onset_offset[tBlink,1]),2] = np.nan

    if re.search(r"Pur", task):
        eye_data_seqs_nan_blink[np.logical_and(eye_data_seqs_nan_blink[:,0] >= blink_onset_offset[tBlink,0],eye_data_seqs_nan_blink[:,0] <= blink_onset_offset[tBlink,1]),1] = np.nan
        eye_data_seqs_nan_blink[np.logical_and(eye_data_seqs_nan_blink[:,0] >= blink_onset_offset[tBlink,0],eye_data_seqs_nan_blink[:,0] <= blink_onset_offset[tBlink,1]),2] = np.nan


# put eye coordinates in deg from center (flip y axis)
matfile = scipy.io.loadmat(mat_filename)
scr_sizeX = matfile['config']['scr'][0,0]['scr_sizeX'][0][0][0][0]
scr_sizeY = matfile['config']['scr'][0,0]['scr_sizeY'][0][0][0][0]
screen_size = np.array([scr_sizeX,scr_sizeY])
ppd = matfile['config']['const'][0,0]['ppd'][0][0][0][0]


eye_data_runs[:,1] = (eye_data_runs[:,1] - (screen_size[0]/2))/ppd
eye_data_runs[:,2] = -1.0*((eye_data_runs[:,2] - (screen_size[1]/2))/ppd)
eye_data_runs_nan_blink[:,1] = (eye_data_runs_nan_blink[:,1] - (screen_size[0]/2))/ppd
eye_data_runs_nan_blink[:,2] = -1.0*((eye_data_runs_nan_blink[:,2] - (screen_size[1]/2))/ppd)

if re.search(r"Pur", task):
    eye_data_seqs[:,1] = (eye_data_seqs[:,1] - (screen_size[0]/2))/ppd
    eye_data_seqs[:,2] = (eye_data_seqs[:,2] - (screen_size[1]/2))/ppd

    eye_data_seqs_nan_blink[:,1] = (eye_data_seqs_nan_blink[:,1] - (screen_size[0]/2))/ppd
    eye_data_seqs_nan_blink[:,2] = (eye_data_seqs_nan_blink[:,2] - (screen_size[1]/2))/ppd



# Save all
# --------
h5_file = "{file_dir}/add/{sub}_{ses}_task-{task}_eyedata.h5".format(file_dir = file_dir, sub = subject, ses = session, task = task)
folder_alias = 'eye_traces'

try: os.system('rm {h5_file}'.format(h5_file = h5_file))
except: pass

h5file = h5py.File(h5_file, "a")
try:h5file.create_group(folder_alias)
except:None

h5file.create_dataset(  '{folder_alias}/eye_data_runs'.format(folder_alias = folder_alias),
                        data = eye_data_runs,dtype ='float32')
h5file.create_dataset(  '{folder_alias}/eye_data_runs_nan_blink'.format(folder_alias = folder_alias),
                        data = eye_data_runs_nan_blink,dtype ='float32')

h5file.create_dataset(  '{folder_alias}/time_start_eye'.format(folder_alias = folder_alias),
                        data = time_start_eye,dtype ='float32')
h5file.create_dataset(  '{folder_alias}/time_end_eye'.format(folder_alias = folder_alias),
                        data = time_end_eye,dtype ='float32')

h5file.create_dataset(  '{folder_alias}/time_start_seq'.format(folder_alias = folder_alias),
                        data = time_start_seq,dtype ='float32')
h5file.create_dataset(  '{folder_alias}/time_end_seq'.format(folder_alias = folder_alias),
                        data = time_end_seq,dtype ='float32')

h5file.create_dataset(  '{folder_alias}/time_start_trial'.format(folder_alias = folder_alias),
                        data = time_start_trial,dtype ='float32')
h5file.create_dataset(  '{folder_alias}/time_end_trial'.format(folder_alias = folder_alias),
                        data = time_end_trial,dtype ='float32')

h5file.create_dataset(  '{folder_alias}/dir_sequence'.format(folder_alias = folder_alias),
                        data = matSeqDir, dtype='int')

if re.search(r"Pur", task):
    h5file.create_dataset(  '{folder_alias}/eye_data_seqs'.format(folder_alias = folder_alias),
                            data = eye_data_seqs, dtype='float32')
    h5file.create_dataset(  '{folder_alias}/eye_data_seqs_nan_blink'.format(folder_alias = folder_alias),
                            data = eye_data_seqs_nan_blink,dtype ='float32')

