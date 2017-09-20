pro plot_stokespa, nwindow, indx, a, $
	qpa, xpy, xmy, xy, yx, $
        pacoeffs, ps=ps, title=title, _REF_EXTRA=_extra

;+
;PURPOSE; plot the Stokes data and their fits versus position angle.

;CALLING SEQUENCE:
;PLOT_STOKESPA, nwindow, indx, a, $
;	qpa, xpy, xmy, xy, yx, $
;        pacoeffs, ps=ps, title=title

;INPUTS:

;	indx, the array of indices speciying the patterns being processed.
;	SOURCENAME...the source name read in 
;	QPA, the array of position angles of the fitted points
;	XPY, XMY, XY, YX, the four arrays of calibrated correlator
;outputs.

;KEYWORDS:
;	PS: if set, varies things a bit to make a nicer postscript plot.
;	TITLE: if set, uses the specified title for the plot. Otherwise
;it uses the default info, consisting of scan nr, freq, srcname.
;
;OUTPUTS: none, just the plot on the screen or the postscript device.
;
;HISTORY:
;       05JUN2009. eliminated common plotcolors and changed colors to
;       sys-defined ones...
;       06jul2015: CH changed annotations (e.g. XY to 2XY)
;-

sourcename= a[ indx[0]].srcname

black=!black
red=!red
green=!green
blue=!blue
grey=!gray

plines= [ 0, 0, 0]
pcolor = [red, green, blue]
bcolor= grey
IF (KEYWORD_SET(PS)) THEN BEGIN 
   bcolor=black
   plines= [ 0,2,3]
   pcolor = [black, BLACK, black]
ENDIF

plotsymbol= [ 7,4,6]

;OPEN WINDOW IF NECESSARY...
IF ( NWINDOW GE 0) THEN BEGIN
   device, window=opnd
   if ( opnd[nwindow] eq 0) then window, nwindow, xs=300, ys=225
   wset,nwindow
ENDIF

; DETERMINE THE YRANGE OF THE PLOT...
ymaxx = max([xmy,xy,yx],MIN=yminn)
yrng = max(abs([yminn,ymaxx])) * [-1,1]

if not keyword_set( title) $ 
   then title='SCAN=' + strcompress(string(a[ indx[0]].scan)) + $
              '  FREQ=' + strcompress( string(a[ indx[0]].cfr)) + $
              '  ' + sourcename
;xtit='Position Angle [deg]'
xtit='Parallactic Angle [deg]'
ytit='Fractional Polarization'
if not keyword_set(PS) then begin
   xtit = strupcase(xtit)
   ytit = strupcase(ytit)
endif

; SET UP THE PLOT...
plot, [0], $
      yra=yrng, YSTYLE=19, $
      xra=[-90,90], /xsty, $
      xtit=xtit, ytit=ytit, $
      tit = title,  /nodata, background=bcolor, _EXTRA=_extra

;stop

cpa = findgen(181)-90.
cpar = 2*!dtor*cpa

; PLOT X-Y...
nr=0
;oplot, modanglem( qpa), xmy, $
oplot, modangle( qpa,180.0,/NEGPOS), xmy, $
        linestyle=nr, psym=plotsymbol[ nr], color=pcolor[nr], _EXTRA=_extra
oplot, cpa, pacoeffs[0,0,nr+1]+ pacoeffs[1,0,nr+1]*cos(cpar) $
	+ pacoeffs[2,0,nr+1]*sin(cpar), color=pcolor[nr], $
	lines= plines[ nr], _EXTRA=_extra

; PLOT XY...
nr=1
;oplot, modanglem( qpa), xy, $
oplot, modangle( qpa,180.0,/NEGPOS), xy, $
        linestyle=nr, psym=plotsymbol[ nr], color=pcolor[nr], _EXTRA=_extra
oplot, cpa, pacoeffs[0,0,nr+1]+ pacoeffs[1,0,nr+1]*cos(cpar) $
	+ pacoeffs[2,0,nr+1]*sin(cpar), color=pcolor[nr], $
	lines= plines[ nr], _EXTRA=_extra

; PLOT YX...
nr=2
;oplot, modanglem( qpa), yx, $
oplot, modangle( qpa,180.0,/NEGPOS), yx, $
        linestyle=nr, psym=plotsymbol[ nr], color=pcolor[nr], _EXTRA=_extra
oplot, cpa, pacoeffs[0,0,nr+1]+ pacoeffs[1,0,nr+1]*cos(cpar) $
	+ pacoeffs[2,0,nr+1]*sin(cpar), color=pcolor[nr], $
	lines= plines[ nr], _EXTRA=_extra

; THROW A LEGEND ON THE PLOT...
if keyword_set(ps) then begin

   ; IF WE HAVE A PS FILE, THROW LINE SEGMENTS DOWN...
   chrhgt = !d.y_ch_size / !y.s[1] / !d.y_vsize

   ypos = yrng[0] + .15*(yrng[1]- yrng[0])
   ;xxyy_norm= convert_coord( -80, 0, /data, /to_normal)
   nr=0
   oplot, [-83, -58], [ypos, ypos], color=pcolor[nr],psym=-plotsymbol[nr], $
          lines= plines[ nr], _EXTRA=_extra
;   xyouts, -57, ypos-0.36*chrhgt, ' X-Y', color=pcolor[nr], _EXTRA=_extra
   xyouts, -57, ypos-0.36*chrhgt, ' XX-YY', color=pcolor[nr], _EXTRA=_extra
   nr=1
   ypos = yrng[0] + .11*(yrng[1]- yrng[0])
   oplot, [-83, -58], [ypos, ypos], color=pcolor[nr],psym=-plotsymbol[nr], $
          lines= plines[ nr], _EXTRA=_extra
   xyouts, -57,ypos-0.36*chrhgt,' 2XY', color=pcolor[nr], _EXTRA=_extra
   nr=2
   ypos = yrng[0] + .07*(yrng[1]- yrng[0])
   oplot, [-83, -58], [ypos, ypos], color=pcolor[nr],psym=-plotsymbol[nr], $
          lines= plines[ nr], _EXTRA=_extra
   xyouts, -57,ypos-0.36*chrhgt, ' 2YX', color=pcolor[nr], _EXTRA=_extra
   
endif else begin
   ; IF PLOTTING ON SCREEN, JUST USE COLORS...
   ypos = yrng[0] + .05*(yrng[1]- yrng[0])
   xyouts, -80, ypos, 'XX-YY', color=pcolor[0], _EXTRA=_extra
   xyouts, '  2XY', color=pcolor[1], _EXTRA=_extra
   xyouts, '  2YX', color=pcolor[2], _EXTRA=_extra
endelse

end
