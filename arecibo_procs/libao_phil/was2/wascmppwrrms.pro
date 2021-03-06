;
; to compute power
; 1. get rms/mean.. use corblauto to do linear fit to find mask where
;    no rfi ..
;
;args:
;badfit:  badfit=1.. continue fitting set, if one fit fails
;                    default is to return without finishing the
;                    other band
;
; savI, brmsar
;
;
pro wascmppwrrms,yymmdd,bcalar=bcalar,needcal=needcal,savdir=savdir,$
        projid=projid,maxrecs=maxrecs,inpdir=inpdir,vrms=vrms,vtp=vtp,$
        recsNeeded=recsNeeded,badfit=badfit

    ln=2.5
    xp=.04 
    if n_elements(needcal) eq 0 then needcal=1
    if n_elements(savdir) eq 0 then savdir='./savdat/'
    if n_elements(projid) eq 0 then projId='a2010'
    if n_elements(maxrecs) eq 0 then maxrecs=600
    if n_elements(recsNeeded) eq 0 then recsNeeded=300
    off2TmMax=6             ; more than 6 secs only use first off
    mjdtojd=2400000.5D
;   rmssav=string(format='(i6.6,".sav")',yymmdd)
    tpsav =string(format='("tp_",i6.6,".sav")',yymmdd)
;
;   restore,rmssav,/verb
;
; computation:
;       mask  = linear fit to rms throw out outliers. remaining is mask
;       if next scan starts within 6 secs of the cal then
;           tpcaloff= avg(lastrec - 1stRecNxtScan)
;       else 
;           tpcaloff= lastrec 
;       endelse
;       calScl=calK/(tpCalOn -tpCalOff)
;       tpCorA= (tp - tpmedian)*calscl
;
; to archive:
;    brmsAr         rms/mean of each file
;    maskAr         used for each file
;    bcalRAr        calOn/calOff
;    tpIAr          totalPwrInfo
;
    tpI={   scan    : 0L    ,$
       fname    : ''    ,$
       npnts    :   0l  ,$  ; number of pnts (600) 
       rmsFitA  : fltarr(2,7),$ ; c0 +c1*lag
       rmsFitB  : fltarr(2,7),$ ;
       maskFract: fltarr(2,7),$ ; fraction used for mask 
   tpCorA   : fltarr(maxrecs,7),$ ; avg tp/median  Tsys -1  Units over 600 pnts
   tpCorB   : fltarr(maxrecs,7),$ ; avg tp Tsys Units
       tpMedian : fltarr(2,7)  ,$ ; value we divided by..polA,B
       calK     : fltarr(2,7)  ,$ ; the cal in kelvins we used
       calScl   : fltarr(2,7)  ,$ ; calK/(calon-caloff) polA,B
       ncalOff  : 0.           ,$ ; 0 no cal, 1 this file, 2 this and next
       az       : 0.           ,$ ; az position for this drift
       za       : 0.           ,$ ; za position for this drift
       jd       : 0D           ,$ ; start of first sample
       alfaAngle: 0.            $ ; alfa rotation angle
        }
;
; working array for a day:
;   gotCalAr[nfiles] = 1==> have cal
;   bcalAr[3,nfiles] = 0 calon,1 first rec file, 2 last rec file
;   maskAr[nfiles]   = from rms fits.. archive
;
verb=-1
deg=1
fsin=0
ndel=5
plver=[0,.02]
nfiles=wasprojfiles(projId,fi,yymmdd1=yymmdd,yymmdd2=yymmdd,dir=inpdir)
if nfiles eq 0 then begin
	inpdirL="not specified"
	if n_elements(inpdir) eq 1 then inpdirL=inpdir
	print,"no files found proj:",projId," date:",yymmdd,$
		  "inpdir:",inpdirL
	return
endif
gotCalAr=intarr(nfiles)         ; 0 no cal, 1 got cal 
iout=0
forceuse1caloff=0
for i=0,nfiles-1 do begin
    wasclose,/all
    print,fi[i].fname
    istat=wasopen(fi[i].fname,desc)
    if istat eq 0 then goto,botloop
    nscans=desc.totscans
    iical=where(desc.scanI.patnm eq 'CAL',ncal)
    maxRecsScan=max(desc.scanI.recsinscan,idata)
    print,needcal,maxRecsScan,desc.scanI[0].nbrds
    if (needcal) and (nscans lt 2) then goto,botloop
    if maxRecsScan lt recsNeeded then goto,botloop
    if desc.scanI[0].nbrds lt 8 then goto,botloop
    if (nscans gt 1) then begin 
        if desc.scanI[1].nbrds lt 8 then goto,botloop
    endif
;
;   figure out number scans in file and where the cal and
;   data is
;

    istat=corinpscan(desc,b,/han,scan=desc.scanI[idata].scan)
    if istat eq 0 then goto,botloop
    if iout eq 0 then begin
        brmsAr =replicate(b[0],nfiles)
        bcalRAr=replicate(b[0],nfiles)
		nlags0=b[0].b1.h.cor.lagsbcout
    endif
	if (corchkstr(brmsar[0],b[0]) eq 0) then begin
		print,"skipping scan:",b[0].b1.h.std.scannumber," struct mismatch"
		continue
	endif
    brmsAr[iout]=corrms(b)
    npts=n_elements(b)
    if iout eq 0 then bcalAr=replicate(b[0],3,nfiles); 1st on, 2,3 1st,last recs
    gotcal=0
    if (ncal ge 1 ) then begin
       istat=corinpscan(desc,bcal,/han,scan=desc.scanI[iical[0]].scan)
       if istat eq 0 then goto,botloop
       gotCalAr[iout]=1
       bcalAr[0,iout]=bcal[0]       ; in case more than one rec
    endif
;
;   a2048 has calon,caloff, datarecs
;   a2010 had  datarecs,calon
;   bcalar: [0] calOn
;           [1] caloff prior to next scans cal
;           [2] caloff after this scans cal
;
    if ncal eq 2 then begin
       istat=corinpscan(desc,bcal,/han,scan=desc.scanI[iical[1]].scan)
       if istat eq 0 then goto,botloop
       bcalAr[2,iout]=bcal[0]       ; cal off that comes after the calon
       forceUse1CalOff=1           ;
    endif else begin
       bcalAr[1,iout]=b[0]
       bcalAr[2,iout]=b[npts-1]
    endelse     
    x=findgen(npts)
    wuse,1
    istat=corblauto(brmsAr[iout],blfit,mask,coef,ndel=ndel,deg=deg,fsin=fsin,$
                plver=plver,verb=verb,badfit=badfit)
    if iout eq 0 then maskAr=replicate(mask,nfiles)
    maskAr[iout]=mask
    tp=corstat(b,mask=mask)
    if iout eq 0 then tpIAr=replicate(tpI,nfiles)
    tpIAr[iout].scan =desc.scanI[0].scan
    tpIAr[iout].fname=desc.filename
    tpIAr[iout].rmsFitA=reform(coef.coefAr[*,0,0:6],2,7)
    tpIAr[iout].rmsFitB=reform(coef.coefAr[*,1,0:6],2,7)
    tpIAr[iout].maskFract=reform(coef.maskfract[*,0:6],2,7)
    tpIAr[iout].npnts    =npts
    tpIAr[iout].az       =median(b.b1.h.std.azttd*.0001D)
    tpIAr[iout].za       =median(b.b1.h.std.grttd*.0001D)
    tpIAr[iout].jd       =b[0].b1.hf.mjd_obs + mjdtojd
    tpIAr[iout].alfaangle=median(b.b1.hf.alfa_ang)
    for j=0,6 do begin &$
        tpIAr[iout].tpMedian[0,j]=median(tp.avg[0,j])
        if tpIAr[iout].tpMedian[0,j] eq 0 then tpIAr[iout].tpMedian[0,j]=1.
        tpIAr[iout].tpMedian[1,j]=median(tp.avg[1,j])
        if tpIAr[iout].tpMedian[1,j] eq 0 then tpIAr[iout].tpMedian[1,j]=1.
        tpIAr[iout].tpCorA[0:npts-1,j]=tp.avg[0,j]/tpIAr[iout].tpMedian[0,j]$
                        - 1.
        tpIAr[iout].tpCorB[0:npts-1,j]=tp.avg[1,j]/tpIAr[iout].tpMedian[1,j] $
            - 1. 
    endfor
    if n_elements(vtp) eq 2 then begin
    ver,vtp[0],vtp[1]
    endif else begin
    ver,-.01,.1 
    endelse
    inc=.01
    !p.multi=[0,1,2]
    lab=string(format=$
    '("scan:",i9," az,za:",f6.1,1x,f6.1," tm:",a)',$
        tpiar[iout].scan,tpiar[iout].az,tpiar[iout].za,$
        fisecmidhms3(tpiar[iout].scan mod 100000L))
    stripsxy,x,tpIAr[iout].tpCorA,0,inc,/step,$
        xtitle='sample in strip',ytitle='totalPwr/median ',$
        title=lab + ' pol A'
    lab=string(format='("medLag0:",7(f5.2,1x))',tpiar[iout].tpmedian[0,0:6])
    note,ln,lab,xp=xp
    stripsxy,x,tpIAr[iout].tpCorB,0,inc,/step,$
        xtitle='sample in strip',ytitle='totalPwr/median ',$
        title='pol B'
    lab=string(format='("medLag0:",7(f5.2,1x))',tpiar[iout].tpmedian[1,0:6])
    note,ln+14,lab,xp=xp
    wuse,0
    if n_elements(vrms) eq 2 then begin
        ver,vrms[0],vrms[1]
    endif else begin
        ver,0,.04
    endelse
    corplot,brmsAr[iout]
    iout=iout+1
botloop:
endfor
nfiles=iout
if nfiles eq 0 then begin
    print,yymmdd,' no files found'
    return
endif
;
; now compute the calscl factors and multiply the data
;
stat=calget(brmsAr[0].b1.h,corhcfrtop(brmsAr[0].b1.h),calval)
for i=0,nfiles-1 do begin
    if gotcalAr[i] then begin
        calTm =bcalAr[0,i].b1.hf.mjd_obs + mjdtojd
        bcalOff=bcalAr[2,i]
        off1Tm =bcalAr[1,i].b1.hf.mjd_obs + mjdtojd
        off2tm=0
        numoff=1
        if (i ne nfiles-1) and (forceUse1CalOff eq 0)  then begin
            off2tm=tpIar[i+1].jd
            if (calTm - off2tm)*86400D lt off2TmMax then begin
                bcalOff2=bcalAr[1,i+1]
                numoff=2
            endif
        endif
;
;   now compute on - off
;   and pwr = (Tsys - median(tsys))
;
        if numoff eq 2 then begin
            dx12=off2tm-off1tm          ; off1,off2 start
            dx  = caltm-off1tm          ; cal start
            bcaloff1=cormath(bcaloff2,bcaloff,/sub)
            scl=dx/dx12
            bcaloff1=cormath(bcaloff1,smul=scl)
            bcaloff=cormath(bcaloff1,bcaloff,/add)
         endif
        caldif=cormath(bcalAr[0,i],bcaloff,/sub)

        a=corstat(caldif,mask=maskAr[i],/median)    ; the cal scale factors
        tpIar[i].calK  =calval
        tpIar[i].calScl=calval/a.avg[*,0:6] ; calK/(calon-calOff)
        tpIar[i].ncalOff=numOff             ; number of cal offs
        for j=0,6 do begin &$
            tpIar[i].tpcorA[*,j]=(tpIar[i].tpcorA[*,j] + 1.) * $
                tpIar[i].tpMedian[0,j]  *  tpIar[i].calScl[0,j] &$
            tpIar[i].tpcorB[*,j]=(tpIar[i].tpcorB[*,j] + 1.)* $
                tpIar[i].tpMedian[1,j]  *  tpIar[i].calScl[1,j] &$
        endfor
        bcalRAr[i]=cormath(bcalar[0,i],bcaloff,/div)
    endif else begin
        tpiar[i].calScl=1.
        tpiar[i].calK  =1.
        tpIar[i].ncalOff=0                  ; number of cal offs
    endelse
endfor
tpIaR=tpiar[0:nfiles-1]
bcalRAr=bcalRAr[0:nfiles-1]
brmsAr=brmsAr[0:nfiles-1]
maskAr=maskar[0:nfiles-1]
;
; rmsar is in rfi directory too .
;
save,tpIaR,bcalRAr,brmsAr,maskAr,file=savDir+tpsav
end
