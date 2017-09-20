;
; remove pitch ramp 10 deg to 20 0 .125 deg
; Constant roll of 0.08 with dome
; Above 10deg, zero-out average roll with shims
; include change in focus from shimming..
;
; @prfinit,@tdinit
; .compile sim1.cmp
; .run shimcmp before calling this routine
;
forward_function prfkposcmp
;.run shimcmp
;
;
hard=1
prfit2dio,prf2d
mkazzagrid,az,za,zastart=2.,zastep=1.
nptsaz=(size(az))[1]
nptsza=(size(az))[2]
npts  =nptsaz*nptsza
az=reform(az,npts)
za=reform(za,npts)
temp=fltarr(npts)
;
; current at 72 degrees...
;
temp1=temp+72.
prfk1=prfkposcmp(az,za,temp1,prf2d)
;
; 	set average pitch above 11 degrees to +/-.04
;
pitchSlope=.125/10.
; rollslope=-.06/10. ; An alternate way with just a ramp
rollCor=.08
pitchCor=0
;
pitch=reform(prfk1.pitch,nptsaz,nptsza)
roll=reform(prfk1.roll,nptsaz,nptsza)
rollp=total(roll,1)/nptsaz
rollp[18]=rollp[17] ; We don't believe the last point.
focus=reform(prfk1.focus,nptsaz,nptsza)
za   =reform(za,nptsaz,nptsza)
;
; fix the pitch
;
ind=where( (abs(za[0,*] - 11.) lt .1))
ind11=ind[0]
for i=ind11,nptsza-1 do begin
	pitch[*,i]=pitch[*,i] - (za[0,i] - 10.)*pitchSlope
	;roll[*,i]=roll[*,i] - (za[0,i] - 10.)*rollSlope
	roll [*,i] = roll[*,i] - rollp[i] - rollCor
	focus[*,i]=focus[*,i] - poly(za[0,i],shimRadFit)
endfor
pitch = pitch + pitchCor
roll = roll + rollCor
print, 'Roll correction:', rollp[ind11:nptsza-1] - rollCor
;
pitch=reform(pitch,npts)
roll=reform(roll,npts)
focus=reform(focus,npts)
za   =reform(za,npts)
zap1=za+.08
prfk2=prfkposcmp(az,zap1,temp1,prf2d,pitch=pitch,roll=roll,focus=focus)
;
prfkT=replicate({prfk},6840,4)
j=0
for i=60,90,10 do begin &$
    temp1=temp+i &$
    zap2=za - .2 + .1*j &$
    prfk=prfkposcmp(az,zap2,temp1,prf2d,roll=prfk2.roll,pitch=prfk2.pitch,$
			focus=prfk2.focus) &$
    prfkt[*,j]=prfk &$
    j=j+1 &$
endfor

;
; do total tension at 60,90 degrees..
;
if hard then pscol,'prfsimm.ps', /full
prfkplot1,prfk1,prfk2,prfkT,pitchSlope*10,rollCor
if hard then hardcopy
x
end
