;+
;NAME:
;imghisteq - histogram equalize an image. return byte array
;
; SYNTAX: bytarr=imghisteq(data,stretch=stretch,invert=invert,minv=minv,
;                          maxv=maxv,sort=sort)
; ARGS:
;      data[m,n] : data array to equalize
; KEYWORDS:
;      stretch[4]: after histogram equalization,
;                  map data range s[0]-s[1] (0 to 255)
;                  to  data range s[2]-s[3] (0 to 255)
;      minv      : float .. minv to use for histeq_no stretchclipping
;      maxv      : float .. maxv to use for histeq_no stretchclipping
;      sort      : if set then histeq via sort
;-
function imghisteq,datAr,stretch=s,invert=invert,minv=minvh,maxv=maxvh,$
         sort=sort
;
; scale the image.place in a separate function it's easy to redefine
; stretch[0..3]   map s[0]->s[1] into s[2]->s[3] below s[0] is 0, above s[1] is
;                 s[3]
;
        cmsize=256.
        binsize=.01             ; after scaling 0 to 255
        minv=float(min(datAr,max=maxv))
        scale=cmsize/(float(maxV)-minV)
        if (n_elements(s) eq 0) then begin
            if keyword_set(sort) then begin
                ind=sort(datAr)
                a=size(datAr)
                npts=n_elements(datAr)
                step=npts/256L
                barr=bytarr(npts)
                j=0L
                for i=0B,254 do begin
                    barr[ind[j:j+step-1]]=i
                    j=j+step
                endfor
                barr[ind[j:*]]=255
                if keyword_set(invert) then barr=255B - barr
                case a[0] of
                    2:return,reform(barr,a[1],a[2],/overwrite)
                    3:return,reform(barr,a[1],a[2],a[3],/overwrite)
                    else:return,barr
                endcase
            endif

            if n_elements(minvh) gt 0 then minv=(minv > minvh)
            if n_elements(maxvh) gt 0 then maxv=(maxv < maxvh)
            scale=cmsize/(float(maxV)-minV)
            if keyword_set(invert) then begin
                return,255B - hist_equal((datAr-minv)*scale,binsize=binsize,$
                    maxv=255.)
            endif else begin
                return,hist_equal((datAr-minv)*scale,binsize=binsize,$
                    maxv=255)
            endelse
        endif
;
;   they want us to stretch
;
        deltax=s[1] - s[0]
        deltay=s[3] - s[2]
        scale2= deltay/deltax
;
;       first scale floats to 0...255.
;
        datAr=hist_equal((datAr-minv)*scale,binsize=binsize)
;
;       now get the indices for s[0],s[1]
        indexAr1=where(datAr lt s[0],count1)
        indexAr2=where(datAr ge s[1],count2)
        datAr= (datAr-s[0])*scale2 + s[3]
        if count1 gt 0 then datAr[indexAr1]=0.
        if count2 gt 0 then datAr[indexAr2]=255.
        if keyword_set(invert) then begin
            return,255B-byte(datAr)
        endif else begin
            return,byte(datAr)
        endelse
end
