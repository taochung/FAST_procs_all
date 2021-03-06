;+
;NAME:
;0atmIntro - Intro to atm routines.
;
;   There are two sets of idl routines to process atm data:
;     - atmxxx To process radar interface taken in the rawdata taking mode. 
;              Use atminit() to initialize idl.
;     - shsxxx To input/process the echotek digital receiver data. 
;              Use shsinit() to initialize idl.
;
;   Starting idl.
;   - To use the atm routines you need to tell idl where to
;     look to get these procedures. You can do it manually each
;     time you run idl, or you can put it in an idl startup file.
;
;     Manually:
;       idl
;       @phil
;         @atminit  (to process the ri data)
;          or
;         @shsinit  (to process the echotek data)
;
;     Using a idl setup file:
;       Suppose your home directory is ~jones.
;       create the file ~jones/.idlstartup
;       add the line        
;          @phil
;       to this file.
;       In your .cshrc file (if you run csh) add the line
;           setenv IDL_STARTUP ~/.idlstartup
;       You can then run idl with :
;           idl
;           @atminit or @shsinit
;       You can also put any other commands in the startup
;       file that you want to be executed each time you 
;       start idl. My startup file contains:
;           !EDIT_INPUT=500
;           @phil
;       Note: if you are running the idl routines at a different site, 
;             replace @phil with the directory at your site.
;       
;0. The atmxxx radar interface routines include:
;
;   - @atminit : call once after starting idl to initialize the atmxxx 
;                routines.
;   - openr    : use the idl routine open to first open the file.
;   - atmget   : input one or more data records
;   - atmpwrcmp: decode and compute power for a barker coded power profile
;                record (you first input the data with atmget().
;   - atmpwrcmp: decode and compute power for a barker coded power profile
;   - plasmacutoff: process single pulse plasma line cutoff records.
;                This routine inputs and processes multiple records.
;   - metmon   : online monitoring of meteor datataking. It can also be 
;                used for offline files.
;
;1. The shsxxx echotek digitial receiver data:
;   - @shsinit : call once after starting idl to initialize the shhxxx 
;                routines.
;   - shsopen   : open a file to process.
;   - shspos    : position to a record in a file
;   - shsget    : read in 1 or more records
;   - shsclose  : close the file when done.
;   -     Support routines not normally called directly:
;   - shshdr_pri: input the primary header
;   - shshdr_dat: input the data header
;   
;   EXAMPLES using the shs routines:
;      The file info is kept in a descriptor structure (below it is called
;      desc). It is generated by the open call shsopen() and should be
;      freed up with the shsclose call.
;
;      A data file contains a primary data header followed by one or
;      more records. The primary header and data headers are in ascii. The
;      data is in binary (typically signed shorts).
;   
;      Records are "tables" in the shs header jargon. A record contains a
;      data header followed by N ipps of data (typically 100).
;
;      To open, read, position, read, close the file you would:
;
; -->  idl      .. start idl
; -->  @phil    .. if you don't have it in your idl startupfile
; -->  @shsinit .. init the shs routines (just needs to be called once).
;
; -->  file='/share/xserve10/nearField/nearField1/nearField_000.shs'
; -->  istat=shsopen(file,desc)
;
;;     Contents of the descriptor:
; help,desc,/st
;
; LUN      LONG     100   ; file descriptor from idl openr
; FNAME    STRING '/share/xserve10/nearField/nearField1/nearF'... filename
; FILESIZE LONG    2136692736  ; total number of bytes in file
; NUMREC   LONG    117         ; total number of records in file
; PHDR     STRUCT  Array[1]    ; structure containing primary header
; DHDR1    STRUCT  Array[1]    ; structure containing data header from 1st rec
; TBLST    LONG    3168        ; byteoffset for start of 1st record
; TBLLEN   LONG    18262304    ; Length of 1 record (header and data).
;
;; primary header:
;
; help,phdr,/st
; VERSION    STRING '0.02'
; LENDIAN    INT           1
; DATE       STRING 'Aug 11,2005'
; TIME       STRING '03:20:50 PM AST'
; OBSERVER   STRING 'MIT'
; OBJECT     STRING 'PLASMA TEST'
; TELESCOPE  STRING '430 MHZ'
; BWMODE     STRING 'ULTRAWIDEBAND'
; CHUSED     STRING '1 CHANNEL'
; COLMODE    STRING 'BURST MODE'
; GATESRC    STRING 'EXTERNAL'
; GATEPLR    STRING 'POSITIVE'
; BURSTCNT   LONG    50176
; DELAYCNT   LONG    0
; SYNC       STRING 'COHERENT-SIA'
; DATAFORMAT STRING '16 BIT COMPLEX'
; CLOCKRATE  DOUBLE  80.000000
; DECIMATE   INT     8
; OUTPUTRATE DOUBLE  10.000000
; RESAMPLER  INT      0
; IPP        LONG    10
; SAMPLETIME DOUBLE  0.10000000
;
;; data header (beginning of each record)
;
; help,desc.dhdr1,/st
; TABLEREC    LONG              0 ;rec number from start of file (cnt from 0)
; TABLESIZE   LONG        9130000 ;number of bytes of data in a record
; DATAWIDTH   INT           2     ;length of a single data sample in bytes
; DATATYPE    STRING '<short>'    ;type of data sample
; NUMDIMS     INT           2     ;number of dimensions in datatbl
; DIM0        LONG          91300 ;number of data samples in 1st dimension
; DIM1        LONG            100 ;number of ipps in 2nd dimension
; NUMCHANNELS INT           1     ;number of chan. 1=single beam,2=dualbeam
; TXSTART     LONG              0 ;starting sample for tx in ipp
; TXLEN       LONG          11200 ;number of samples in tx window
; DATASTART   LONG          12000 ;starting sample in data window
; DATALEN     LONG          80000 ; number of samples in data window
; NOISESTART  LONG          92000 ;starting sample for noise (cal) window
; NOISELEN    LONG            100 ;number of samples in noise(cal) window
; SYSTIME     STRING '15:17:16'   ;time for record (starttime ??)
; AZ          FLOAT        449.999;az position (deg) for rec (at start??)
; ZAGREG      FLOAT        8.46800;za (dome) position for rec
; ZACH        FLOAT    0.000200000;za (ch) position for rec.
;
;;Notes:
;;   Above a Sample is an I or Q data sample. There are two data samples for
;; each time sample. 
;;   The startTime is the data sample if all of the samples were kept for
;; output (they're  not). There is usually a gap between the tx window
;; and the data window and the datawindow and the cal window.
;;   To find the position in the data buffer for the data window you must
;; skip over the txLen. To find the starting time for the data window you
;; multiply the datastart *.5*sampletime (.5 since there are 2 data samples
;; per time sample.
;;   shsget() seperates out the tx,data, and cal data for you.
;
;;
;;     Input 10 records (of 100 ipps each)
;;
; -->  istat=shsget(desc,d,nrec=10)
;     
;;     in this case d is an array of 10 records:
;;     the structure contents are:
;
; help,d,/
;
; IDL> help,d,/st
; DHDR   STRUCT    -> <Anonymous> Array[1]; hods the data header
; NIPPS  LONG               100           ; number of ipps in record
; D1     STRUCT    -> <Anonymous> Array[1]; the data
;
; help,d.d1,/st
;
; TX     INT       Array[2, 5600, 100] ;tx data:[i/q,5600txsmples ,100 ipps]
; DAT    INT       Array[2, 40000, 100];hghtdat:[i/q,40000 smmples,100 ipps]
; CAL    INT       Array[2, 50, 100]   ;caldat :[i/q,50 calsmples ,100 ipps]
;
;; --> position to a random record in the file
;
;   rec=35
;   istat=shspos(desc,rec)
;
;
;NOTES:
;   - The shspos() routine assumes that all records are the same length
;     as the first record (this is supposed to be true).
;-
