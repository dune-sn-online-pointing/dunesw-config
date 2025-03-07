# This is currently in a very non-generic state, apologies.
# I'll try to make it better and not user-dependent through a json settings file.

import numpy as np
import matplotlib.pyplot as plt

# This script is used to read the output files of the speed tests and plot the execution time vs the number of events

nEvents = [5,10,15,20,30,40,50,60,70,80,90,100]
exec_timeCCDir = np.zeros(len(nEvents))
exec_timeESDir = np.zeros(len(nEvents))
exec_timeIsotropic = np.zeros(len(nEvents))

timeReportCPU_CCDir = np.zeros(len(nEvents))
timeReportCPU_ESDir = np.zeros(len(nEvents))
timeReportCPU_Isotropic = np.zeros(len(nEvents))
timeReportReal_CCDir = np.zeros(len(nEvents))
timeReportReal_ESDir = np.zeros(len(nEvents))
timeReportReal_Isotropic = np.zeros(len(nEvents))

# read files in the form job.speed-test-CC-directions.10057551.0.out from 0 to 5
# and read the number after the words "Simulation took " and store it in the corresponding vector

folder = "/home/virgolaema/dune/samples_validation/"

for i in range(len(nEvents)):
    filenameCC = folder + f"job.speed-test-CC-directions.10057797.{i}.out"
    filenameES = folder + f"job.speed-test-ES-directions.10057798.{i}.out"
    filenameIsotropic = folder + f"job.speed-test-isotropic-more.10057799.{i}.out"
    try:
        with open(filenameCC, 'r') as f:
            for line in f:
                if 'Simulation took' in line:
                    exec_timeCCDir[i] = float(line.split()[2])
                # add the reading of these other two times from this line
                # TimeReport CPU = 15.945796 Real = 23.837419
                if 'TimeReport CPU' in line:
                    timeReportCPU_CCDir[i] = float(line.split()[3])
                    timeReportReal_CCDir[i] = float(line.split()[6])
                
    except:
        exec_timeCCDir[i] = 0
    try:
        with open(filenameES, 'r') as f:
            for line in f:
                if 'Simulation took' in line:
                    exec_timeESDir[i] = float(line.split()[2])
                if 'TimeReport CPU' in line:
                    timeReportCPU_ESDir[i] = float(line.split()[3])
                    timeReportReal_ESDir[i] = float(line.split()[6])
    except:
        exec_timeESDir[i] = 0
    try:
        with open(filenameIsotropic, 'r') as f:
            for line in f:
                if 'Simulation took' in line:
                    exec_timeIsotropic[i] = float(line.split()[2])
                if 'TimeReport CPU' in line:
                    timeReportCPU_Isotropic[i] = float(line.split()[3])
                    timeReportReal_Isotropic[i] = float(line.split()[6])
    except:
        exec_timeIsotropic[i] = 0
        
# if a value is zero, average over the previous and next value
for i in range(len(nEvents)-1):
    if exec_timeCCDir[i] == 0:
        exec_timeCCDir[i] = (exec_timeCCDir[i-1] + exec_timeCCDir[i+1]) / 2
    if exec_timeESDir[i] == 0:
        exec_timeESDir[i] = (exec_timeESDir[i-1] + exec_timeESDir[i+1]) / 2
    if exec_timeIsotropic[i] == 0:
        exec_timeIsotropic[i] = (exec_timeIsotropic[i-1] + exec_timeIsotropic[i+1]) / 2
        
# if the last value is zero, set it to the previous
if exec_timeCCDir[-1] == 0:
    exec_timeCCDir[-1] = exec_timeCCDir[-2]
if exec_timeESDir[-1] == 0:
    exec_timeESDir[-1] = exec_timeESDir[-2]
if exec_timeIsotropic[-1] == 0:
    exec_timeIsotropic[-1] = exec_timeIsotropic[-2]


plt.plot(nEvents, exec_timeCCDir, label='CCDir')
plt.plot(nEvents, exec_timeESDir, label='ESDir')
plt.plot(nEvents, exec_timeIsotropic, label='Isotropic')

plt.xlabel('Number of events')
plt.ylabel('Execution time [s]')
plt.title('Execution time vs number of events')
# start plot from y 0
plt.ylim(0)
plt.legend()
plt.savefig('exec_time.png')

# new plot for CPU time
plt.plot(nEvents, timeReportCPU_CCDir, label='CCDir')
plt.plot(nEvents, timeReportCPU_ESDir, label='ESDir')
plt.plot(nEvents, timeReportCPU_Isotropic, label='Isotropic')

plt.xlabel('Number of events')
plt.ylabel('Execution time [s]')
plt.title('Time Report CPU vs number of events')
# start plot from y 0
plt.ylim(0)
plt.legend()
plt.savefig('time_report_cpu.png')

# new plot for Real time
plt.plot(nEvents, timeReportReal_CCDir, label='CCDir')
plt.plot(nEvents, timeReportReal_ESDir, label='ESDir')
plt.plot(nEvents, timeReportReal_Isotropic, label='Isotropic')

plt.xlabel('Number of events')
plt.ylabel('Execution time [s]')
plt.title('Time Report Real vs number of events')
# start plot from y 0
plt.ylim(0)
plt.legend()    
plt.savefig('time_report_cpu.png')
