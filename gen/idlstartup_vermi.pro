common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
;common plotcolors, black, red, green, blue, cyan, magenta, yellow, white, grey 

print, 'STARTUP FILE IS /dzd2/heiles/idl/gen/idlstartup_vermi.pro'

;------------------------THE USUAL PATHS---------------------------

;stop
;do arecibo thing for mas. it uses a different definition for 'addpath'.
;aodefdir.pro must be customized for each computer. we do this by
;invoking the file aodefdir_vermi or aodefdir_vermu; these define the
;function aodefdir tailored for vermi or vermu, respectively.
.run $DZD4/arecibo/procs/libao_phil/gen/aodefdir_vermi
;.run $DZD4/arecibo/procs/libao_phil/gen/aodefdir_vermu
.run $DZD4/arecibo/procs/libao_phil/gen/addpath
addpath, 'gen'
@masinit

;MAKE SURE WE COMPILE OUR OWN VERSIONS OF ADDPATH AND WHICH...
.run $DZD2/idl/gen/path/addpath
addpath, getenv( 'CARLPATH') + 'idl/gen/path/'
;!path= expand_path( getenv( 'CARLPATH') + 'idl/gen/path/') + ':' + !path
;.run addpath
.run which

;ADD IDL NATIVE UTILITIES...
;addpath, getenv('IDL_DIR') + '/lib/utilities'

;THE FOLLOWING PROVIDES A SOME WAVELET FUNCTIONS THAT DO NOT SEEM
;	TO EXIST IN IDL6.2...
;addpath, '/apps1/idl_6.0/lib/wavelet/source/


;---------------------ADD ARECIBO-RELATED PATHS-------------------------
addpath, getenv('DZD4') + '/arecibo/procs'
addpath, getenv('DZD4') + '/arecibo/procs/gen'
addpath, getenv('DZD4') + '/arecibo/procs/libao_phil', /expand
addpath, getenv('DZD4') + '/arecibo/procs/z17', /expand
addpath, getenv('DZD4') + '/arecibo/procs/zm2'

;---------------------ADD CARL-RELATED PATHS-------------------------
addpath, getenv( 'CARLPATH')+ 'idl/ay120coords' 
addpath, getenv( 'CARLPATH')+ 'idl/CodeIDL' 
addpath, getenv( 'CARLPATH') + 'idl/goddard' 
addpath, getenv( 'CARLPATH') + 'idl/goddard_jan2007', /expand 
addpath, getenv( 'CARLPATH')+ 'idl/idlutils', /expand 
addpath, getenv( 'CARLPATH')+ 'idl/gen', /expand 

;OBSERVATORY COORDINATES...
;@/home/heiles/pro/carls/aostart.idl
;these are for arecibo...
print, 'loading ARECIBO coordinages into COMMON ANGLESTUFF'
common anglestuff, obslong, obslat, cosobslat, sinobslat
obslong = ten(66,45,10.8)
obslat = ten(18,21,14.2)
cosobslat = cos(!dtor*obslat)
sinobslat = sin(!dtor*obslat)
defsysv, '!obsnlat', obslat
defsysv, '!obselong', 360.d0- obslong
defsysv, '!obswlong', obslong

;-------------------DI\O STABDARD IDL SETUP STUFF----------------------

; WE'RE GOING TO SET THE PLOT DEVICE TO X WINDOWS...
set_plot, 'X'
                                                                                
; SET THE NUMBER OF LINES YOU WANT IDL TO SAVE FOR UP-ARROW CALLBACK...
!EDIT_INPUT=200

;; COMPILE COLOR TABLE ROUTINES...
;.compile setcolors, stretch
 
; Find out all you want about X Windows Visual Classes by looking in the
; online help under: X Windows Device Visuals
 
; EXPLAIN THE X WINDOWS VISUAL CLASSES...
print, 'X WINDOWS VISUAL CLASSES:', format='(%"\N",A)'
print, '<g> : GrayScale 8-bit.'
print, '<p> : PseudoColor 8-bit, only available color indices allocated.'
print, '<2> : PseudoColor 8-bit, all 256 color indices allocated.'
print, '<t> : TrueColor 24-bit, a static color display.'
print, '<d> : DirectColor 24-bit, a dynamic color display.'
print, '<s> : System-restricted color display is selected.'
print, '<n> : Dont set any visual class.', format='(A,%"\N")'
 
; SET THE X WINDOWS VISUAL CLASS...
repeat begin &$
   print, format = $
'($,"<g>ray, <p>seudo, pseudo<2>56, <t>rue, <d>irect, <n>othing, or <s>ystem: ")' &$
   mode = strlowcase(get_kbrd(1)) & print &$
   case (mode) of &$
     'g' : device, Gray_Scale=8,    retain=2 &$     ; GRAYSCALE
     'p' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR
     '2' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR 256
     't' : device, True_Color=24,   retain=2 &$     ; TRUECOLOR
     'd' : device, Direct_Color=24, retain=2 &$     ; DIRECTCOLOR
     'n' : print, 'no visual class selected' &$
     'q' : exit &$
    else : if (mode ne 's') then print, 'Try again! (<q> to quit!)' &$
   endcase &$
endrep until (strpos('gp2tdns',mode) ne -1)

; LET OPERATING SYSTEM TAKE CARE OF BACKING STORE...
;if ( mode ne 'n') then device, RETAIN=2

; USE UNDOCUMENTED DEVELOPERS KEYWORD /INSTALL_COLORMAP TO ENSURE
; PROPER DIRECTCOLOR BEHAVIOR ON LINUX MACHINES...
if ( mode ne 'n') then if strmatch(getenv('OSTYPE'),'linux') then device, /INSTALL_COLORMAP

; GET IDL COLOR INFORMATION AND SET UP SYSTEM VARIABLES WITH BASIC
; PLOT COLOR NAMES...
if ( mode ne 'n') then setcolors, /SYSTEM_VARIABLES, PSEUDO256=(mode eq '2')
if ( mode ne 'n') then $
        defsysv, '!pcolr', [!gray, !red, !green, !blue, !yellow, !magenta, !cyan, $
        !orange, !forest, !purple]
if ( mode ne 'n') then defsysv, '!grey', !gray
 
;stop
                                                                                
; SET THE CURSOR TO A THIN CROSS (33) OR 
;*****tim's favorite***** THIN CROSS WITH DOT (129)...
; CARL'S PREFERENCE IS AN ARROW POINTER (46)
defsysv, '!cursor_standard', 46
if ( mode ne 'n') then device, CURSOR_STANDARD=!cursor_standard
if ( mode ne 'n') then window, 0, xsize=300, ysize=225 ;, retain=2
if ( mode ne 'n') then window, 1, xsize=300, ysize=225 ;, retain=2

;;----THE FOLLOWING SECTION DOES CARL'S COLOR SCHEME FOR BACKWARDS COMPATIBILITY-----
;nrbits=0
;if ( mode ne 'n') then nrbits=1
;@start_plotcolors.idl
;defsysv, '!grey', !gray
;red=!red
;green=!green
;blue=!blue
;yellow=!yellow
;magenta=!magenta
;white=!white
;black=!black
;grey=!grey
;gray=!gray
;tvlct, r_orig, g_orig, b_orig, /get
;tvlct, r_curr, g_curr, b_curr, /get
                                                                                
;if ( mode ne 'n') then plotcolors

delvar, mode
                                                                                
; BELOW I'M REDEFINING SOME KEY COMBINATIONS...
; GET RID OF THE PRINT LINES IF THE OUTPUT BUGS YOU...
; OR GET RID OF THE DEFINITIONS IF YOU'RE NOT GOING TO USE THEM...
                                                                                
; REDEFINE SOME KEYS...
define_key, /control, '^F', /forward_word
print, 'Redefining CTRL-F : Move cursor forward one word'
define_key, /control, '^B', /back_word
print, 'Redefining CTRL-B : Move cursor backward one word'
define_key, /control, '^K', /delete_eol
print, 'Redefining CTRL-K : Delete to end of line'
define_key, /control, '^U', /delete_line
print, 'Redefining CTRL-U : Delete to beginning of line'
define_key, /control, '^D', /delete_current
print, 'Redefining CTRL-D : Delete current character under cursor'
define_key, /control, '^W', /delete_current
print, 'Redefining CTRL-W : Delete word to left of cursor', format='(A,%"\N")'

print, 'to use a 256-entry color table, turn off decomposed color: DEVICE, DEC=0'
print, ''
print, 'STARTUP FILE IS /home/heiles/dzd2/idl/gen/idlstartup_vermi.pro
print, '!!'
