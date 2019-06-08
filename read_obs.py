from scipy.io import FortranFile
import datetime as dt                #Datetime operations
import numpy as np                   #Numpy
import os
import gc

#=========================================================================================================
# CONFIGURATION SECTION
#=========================================================================================================

#General section
basedir = '/home/paula.maldonado/datosmunin/RIKEN2019'
scriptspath = basedir + '/scripts/radar_qc_so'                       #Main scripts directory
datadir = basedir + '/DATA/OBS/OBS_RRA'        #Main radar data directory
dataoutdir = basedir + '/DATA/OBS/OBS_SCALE'

ini_time = '20181109180000'   #Initial time
end_time = '20181111180000'   #Final time
obstype_to_process = ['ADPUPA', 'AIRCFT', 'SATWND', 'ADPSFC', 'SFCSHP', 'ASCATW', 'AIRSRT', 'ADPAUT', 'BOYASX']     #Observation type list
file_type_list = ['.dat']      #File extension list

#LETKF section 
window_type = 'centered'
freq = 600                            #Window frequency (seconds)
anal_freq = 3600                      #Analysis freq (seconds)
#grid = [10000, 1000, 15e3, 240e3]     # dx , dz , zmax , rmax
#opts = {'CZH': [4001, 5, 0]}

#=========================================================================================================
# END OF CONFIGURATION SECTION
#=========================================================================================================

import sys
sys.path.append( basedir + '/scripts/common/')
sys.path.append( scriptspath + '/radar_qc/src/python/' )
import util as ut                #Python util
import operational_tools as ot   #Operational tools.

#letkfdir = dataoutdir + '/OBS_SCALE_10KM_' + str(freq//60) + 'MIN'

anal_dates = ut.get_dates([ini_time, end_time, anal_freq])
for anl_date in anal_dates:

      print('')
      print('============================================')
      print('ANALYSIS DATE : ', anl_date)
      print('============================================')

      OUTDIR = dataoutdir + '/' + dt.datetime.strftime(anl_date, '%Y%m%d_%H')
      os.makedirs(OUTDIR, exist_ok=True)

      #Determine assim window 
      if window_type == 'centered':
         iniwindow = anl_date - dt.timedelta(minutes=np.floor(anal_freq/60/2.0))
         endwindow = anl_date + dt.timedelta(minutes=np.floor(anal_freq/60/2.0))
      elif window_type == 'backward':
         iniwindow = anl_date - dt.timedelta(minutes=anal_freq)
         endwindow = anl_date
      elif window_type == 'forward':
         iniwindow = anl_date
         endwindow = anl_date + dt.timedelta(minutes=anal_freq)

      #Create list to store fields according to time slot
      nslot = int(((endwindow - iniwindow)//freq).total_seconds())
      time_slot = [(iniwindow - anl_date).total_seconds() + i*freq for i in range(nslot+1)]

      #Obtenemos las fechas que van a ser procesadas.
      time = ut.date2str(endwindow)
      prev_time = ut.date2str(iniwindow)
      print('')
      print('=============================================================================')
      print('We will process all the files within the following dates:' )
      print( prev_time )
      print( time )
      print('=============================================================================')
      print('')

      #Obtenemos la lista de archivos.
      print('')
      print('=============================================================================')
      print(' GETTING FILE LIST ')
      print('=============================================================================')
      print('')

      file_list = ot.get_file_list( datadir , prev_time , time , time_search_type='filename' , file_type_list = file_type_list )

      #Iteramos sobre la lista de archivos
      use_idx = []
      for ifile, filename in enumerate(file_list):

         file_name = os.path.basename(filename)
         file_instrument = file_name.split('.')[0].split('_')[0]
         file_time = file_name.split('.')[0].split('_')[1]
         
         if file_instrument in obstype_to_process and os.stat(filename).st_size != 0:

            print('')
            print('=============================================================================')
            print(' READING FILE ' ,  ifile,  ' : ', filename)
            print('=============================================================================')
            print('')

            if ifile not in use_idx:
               use_idx.append(ifile)
               tmp_ifile = ifile

               #Check if file is repeated and keep the larger one
               for i in range(tmp_ifile+1, len(file_list)):

                  if file_name in file_list[i]:
                     print('FILE REPETED : ', file_name)
                     print('INDEX : ', tmp_ifile, i)
                  
                     if os.stat(filename).st_size <= os.stat(file_list[i]).st_size:
                        filename = file_list[i]
                        tmp_ifile = i
                        use_idx.append(i)
                     print('WE WILL KEEP FILE  : ', filename)
   
                 
               #Set time slot value according to file_time
               mydate = ut.str2date(file_time)
               tslot_sec = (mydate - anl_date).total_seconds()

               #Check tslot_sec is correct
               if tslot_sec in time_slot:
 
                  nrec=0

                  with open (filename, 'r') as f:
                     fsize = os.fstat(f.fileno()).st_size
                     #while we haven't yet reached the end of the file...
                     while f.tell() < fsize:

                        header = np.fromfile(f, dtype=np.float32, count=1)
                        data = np.fromfile(f, dtype=np.float32, count=7)
                        header = np.fromfile(f, dtype=np.float32, count=1) 
                        new_data = np.append(data, tslot_sec)

                        #Stack register to global variable   
                        if nrec == 0:
                           dataout = new_data
                        else:
                           dataout = np.vstack((dataout, new_data))

                        nrec += 1
        
                  print('NUMBER OF RECORDS :' + str(nrec))

               print('')
               print('=============================================================================')
               print(' WRITING FILE : ', file_name)
               print('=============================================================================')
               print('')

               DATAOUT = np.float32(dataout)
               fileout = OUTDIR + '/' + file_name

               fout = FortranFile(fileout, 'w')
               for i in range(DATAOUT.shape[0]):
                  fout.write_record(DATAOUT[i,:])

               #Close file
               fout.close()
            else:
               print('FILE ALREADY USED')


 
   

