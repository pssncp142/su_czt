;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Yigit Dallilar 17/06/2012
;functions :
;-getdata(/data,/cnt)
;-getinfo(/pos,/ener,/numb)
;-eventcount(/ind,/cnt)
;-eventgetinfo(evindex,/pos,/ener,/numb)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;detrapping properties will be added
FUNCTION trapping,dist,trapindex,traptime,ind=ind,time=time


IF keyword_set(ind) THEN RETURN, istrapped
IF keyword_set(time) THEN RETURN, time
RETURN,-1
END


;detrapping properties will be added
FUNCTION detrapping,i,trapindex,traptime,ind=ind,time=time

IF keyword_set(ind) THEN RETURN, istrapped
IF keyword_set(time) THEN RETURN, time
RETURN,-1
END

FUNCTION calcaccel,aener,apos,onindex,cloudnumb

accel = dblarr(cloudnumb)
field = dblarr(cloudnumb)
efield = elecfield(apos,onindex)
cfield = coulombfield(apos,aener,onindex,cloudnumb)
field(onindex)=efield(onindex)+cfield(onindex)  
force(0,onindex)=field(0,onindex)*aener(onindex)*(conste)/(bandgap)
force(1,onindex)=field(1,onindex)*aener(onindex)*(conste)/(bandgap)
force(2,onindex)=field(2,onindex)*aener(onindex)*(conste)/(bandgap)
accel(onindex)=force(onindex)/(constm)

RETURN,accel
END

FUNCTION coulombfield,apos,aener,onindex,cloudnumb

cfield=dblarr(3,cloudnumb)

apos = apos*1000
cntr=0
cnst=1.30968e-10;(conste)/(4*pi*epsilon)
bandgap = 2

FOR i=0,cloudnumb-1 DO BEGIN 

   fieldvector=dblarr(3,cloudnumb)
   selcloud=dblarr(3,cloudnumb)
   rcube=dblarr(cloudnumb)

   IF (i EQ onindex(cntr)) THEN BEGIN

    fieldvector(*,onindex)=apos(*,onindex)

    selcloud(0,*) = selcloud(0,*) + apos (0,i)
    selcloud(1,*) = selcloud(1,*) + apos (1,i)
    selcloud(2,*) = selcloud(2,*) + apos (2,i)

    fieldvector(*,onindex) = selcloud(*,onindex) - apos(*,onindex)

    ;; think about they all should be zero
    newindex = WHERE ( (fieldvector(0,*)+fieldvector(1,*)+fieldvector(2,*)) NE 0 )

    rcube(newindex) = SQRT(fieldvector(0,newindex)^(2)+fieldvector(1,newindex)^(2)+fieldvector(2,newindex)^(2))^(-3)

    fieldvector(0,newindex) = rcube(newindex)*fieldvector(0,newindex)
    fieldvector(1,newindex) = rcube(newindex)*fieldvector(1,newindex)
    fieldvector(2,newindex) = rcube(newindex)*fieldvector(2,newindex)

    FOR j=0,cloudnumb-1 DO cfield(0,i)=cfield(0,i)+fieldvector(0,j)*cnst*aener(j)/bandgap
    FOR j=0,cloudnumb-1 DO cfield(1,i)=cfield(1,i)+fieldvector(1,j)*cnst*aener(j)/bandgap
    FOR j=0,cloudnumb-1 DO cfield(2,i)=cfield(2,i)+fieldvector(2,j)*cnst*aener(j)/bandgap

    cntr = cntr + 1

  ENDIF
ENDFOR

RETURN, cfield
END

FUNCTION elecfield,apos,onindex,cloudnumb
efield = dblarr(3,cloudnumb)
efield(2,*)=efield(2,*)+0.5
RETURN, efield
END

FUNCTION endtransport,apos,onindex

RETURN,isended
END

FUNCTION transport,evindex,bandgap

apos = eventgetinfo(evindex,/pos)
aener = eventgetinfo(evindex,/ener)
index = geteventindex(/ind)
cloudnumb = (index(evindex)-index(evindex-1))
avel=dblarr(3,cloudnumb)
aaccel=dblarr(3,cloudnumb)
istrapped=intarr(1,cloudnumb)
istrapped = istrapped + 1
isended=intarr(1,cloudnumb)
isended = isended + 1
dist = dblarr(cloudnumb)
traptime = dblarr(cloudnumb)
ndist = dblarr(cloudnumb)

FOR i=0,1000 DO BEGIN

  trapindex = WHERE (istrapped EQ 1)
  endindex = WHERE (isended EQ 1)
  isavail = istrapped*isended
  onindex = WHERE (isavail EQ 1)

  aaccel(onindex)=calcaccel(aener,onindex)
  avel(onindex)=accel(onindex)*intrvl+avel(onindex)
  npos(onindex)=avel(onindex)*intrvl+apos(onindex)
  ndist(onindex) = SQRT ((npos(0,onindex)-apos(0,onindex))^2+(npos(1,onindex)-apos(1,onindex))^2+(npos(2,onindex)-apos(2,onindex))^2)
  apos(onindex) = npos(onindex)
  dist(onindex) = ndist(onidex) + dist(onindex)

  istrapped=trapping(dist,trapindex,traptime,/ind)
  traptime=trapping(dist,trapindex,traptime,/time)
  istrapped=detrapping(i,trapindex,traptime,/ind)
  traptime=detrapping(i,trapindex,traptime,/time)

  isended=endtransport(pos,endindex)

ENDFOR
END

;returns infromations from file according to keywrods
;data -> returns all characters form file as bytes
;cnt -< returns number of characters
;return -1 if keyword fails
FUNCTION getdata,data=data,cnt=cnt
;getting values as bytes from file
openr,1,"electron_clouds.bin"
nbyte = fstat(1)
ndata = nbyte.size/4
fdata=bytarr (4,ndata)
readu,1,fdata
close,1

;return data to double format
data=dblarr(ndata)
data = double(fdata(0,*))+(double(fdata(1,*))*256)+$
(double(fdata(2,*))*256*256)+(double(fdata(3,*))*256*256*256)
negval = where (data GT 2147483647)
data(negval) = data(negval) - 4294967295

IF keyword_set(cnt) THEN RETURN, ndata
IF keyword_set(data) THEN RETURN, data

RETURN, -1

END


;reads from file and return according to keywords
;pos -> return position vector of all clouds
;ener -> return energy of all clouds
;numb -> return index of all clouds
;if keyword is not specified return -1
FUNCTION getinfo,pos=pos,ener=ener,numb=numb

data=getdata(/data)
ndata=getdata(/cnt)

;;return information as keyword specified 

ncloud = ndata/5

anumb=dblarr(1,ncloud);creation of final arrays
apos=dblarr(3,ncloud)
aener=dblarr(1,ncloud)

;writing data to arrays
FOR i = 0,(ncloud-1) DO anumb(0,i)=data(5*i)
FOR i = 0,(ncloud-1) DO apos(0,i)=data(5*i+1)/1000000
FOR i = 0,(ncloud-1) DO apos(1,i)=data(5*i+2)/1000000
FOR i = 0,(ncloud-1) DO apos(2,i)=data(5*i+3)/1000000
FOR i = 0,(ncloud-1) DO aener(0,i)=data(5*i+4)/1000

;return as the keyword specified
IF keyword_set(pos) THEN RETURN, apos
IF keyword_set(ener) THEN RETURN, aener
IF keyword_set(numb) THEN RETURN, anumb

;if the keyword is not specified return -1
RETURN,-1

END

;return information as keyword specified
;ind returns index of first clouds
;cnt returns number of events
;if keyword fails return -1
FUNCTION eventcount,ind=ind,cnt=cnt

data = getdata(/data)

numb = getinfo(/numb)
index = where (numb eq 0,count)

IF keyword_set(ind) THEN RETURN, index
IF keyword_set(cnt) THEN RETURN, count

RETURN, -1

END

FUNCTION geteventindex,nofev=nofev,ind=ind
nofevents=eventcount(/cnt)
index=dblarr(nofevents+1)
index(0:nofevents-1) = eventcount(/ind)
index(nofevents)=getdata(/cnt)/5
IF keyword_set(nofev) THEN RETURN,nofevents
IF keyword_set(ind) THEN RETURN,index
RETURN,-1
END

;return information as keyword specified
;numb returns index of clouds
;pos returns x,y,z position of clouds
;ener returns energy deposition of the clouds
;if keyword fails return -1
;evindex should be small from (count-1) otherwise return -2
FUNCTION eventgetinfo,evindex,pos=pos,ener=ener,numb=numb

data = getdata(/data)

index = geteventindex(/ind)
nofevents = geteventindex(/nofev)
print,index
print,nofevents

IF (evindex GT nofevents) THEN RETURN, -2

anumb = getinfo(/numb)
apos = getinfo(/pos)
aener = getinfo(/ener) 

fnumb=dblarr(1,index(evindex)-index(evindex-1))
fener=dblarr(1,index(evindex)-index(evindex-1))
fpos=dblarr(3,index(evindex)-index(evindex-1))

fnumb(0,*) = anumb(0,(index(evindex-1)):(index(evindex)-1))
fpos(0,*) = apos(0,(index(evindex-1)):(index(evindex)-1))
fpos(1,*) = apos(1,(index(evindex-1)):(index(evindex)-1))
fpos(2,*) = apos(2,(index(evindex-1)):(index(evindex)-1))
fener(0,*) = aener(0,(index(evindex-1)):(index(evindex)-1))

;returning data
IF keyword_set(pos) THEN RETURN, fpos
IF keyword_set(ener) THEN RETURN, fener
IF keyword_set(numb) THEN RETURN, fnumb

;no keyword returns -1
RETURN, -1

END

