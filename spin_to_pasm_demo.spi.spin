'' =================================================================================================
''
''   File....... spin_to_pasm_demo.spin
''   Purpose.... 
''   Author..... Jon "JonnyMac" McPhalen (aka Jon Williams)
''               Copyright (c) 2011 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.term
''   Started.... 
''   Updated.... 04 JAN 2011
''
'' =================================================================================================


con

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                                          ' use 5MHz crystal
' _xinfreq = 6_250_000                                          ' use 6.25MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000


con

  RX1 = 31
  TX1 = 30
  SDA = 29
  SCL = 28


con 

  #1, HOME, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR, #16, CLS      ' PST formmatting control


obj

  term : "fullduplexserial"


var

  long  cog
  long  cogcmd
  long  param1
  long  param2
  long  param3
  long  param4
  long  result1
  long  result2 
  long  time
  long  timetest
  long  ratio
  long  prevtime
  long  totratio
  long  gui


pub main | val1, val2, wa1, wa2

  gui:=1
  start                                                         ' start math cog

  term.start(RX1, TX1, %0000, 115_200)
  waitcnt(cnt + (1 * clkfreq))          
  wa1:=0
  wa2:=0
  term.tx(CLS)
  term.str(string("Const Mult Test", CR, CR))
  if gui
    repeat val1 from 1073741824 to 1073741825
      repeat val2 from 32 to 32
        term.dec(val1)
        term.tx(TAB)
        term.dec(val2)
        term.tx(TAB)
        addem(val1, val2 , wa1, wa2)
        term.bin(result2,32)
        term.bin(result1,32)
        term.tx(TAB)
        term.dec(time)
        ratio:=time/timetest
        if timetest==1
            ratio:=1
            totratio:=1   
        timetest:=time            
        totratio:=totratio*ratio
        term.tx(TAB)
        term.dec(totratio)
        term.tx(CR)
  {else
    repeat val1 from 2147480000 to 2147483647
      repeat val2 from 2147480000 to 2147483647
       term.dec(addem(val1, val2 , wa1, wa2)) 
       ratio:=time/timetest
       if timetest==1
                             ratio:=1
                             totratio:=1   
       timetest:=time
       totratio:=totratio*ratio
    term.dec(totratio) }
  else
       val1:=0
       val2:=0
       wa1:=0
       wa2:=0
       term.dec(addem(val1, val2 , wa1, wa2)) 

  repeat
    waitcnt(0)

 
pub pause(ms) | t

'' Delay program ms milliseconds

  t := cnt - 1088                                               ' sync with system counter
  repeat (ms #> 0)                                              ' delay must be > 0
    waitcnt(t += MS_001)


pub start

'' Start math cog (PASM)

  stop
  cog := cognew(@entry, @cogcmd) + 1
  timetest := 1
  return (cog > 0)


pub stop

'' Stop math cog (if running)

  if cog
    cogstop(cog~ - 1)


pub addem(value1, value2, wal1, wal2)

'' returns value1 + value2

  longmove(@param1, @value1, 4)                                 ' copy parameters
  cogcmd := 1                                                   ' alert cog
  repeat while cogcmd                                           ' wait for result

  return result1                                              ' return to caller


dat

                        org     0

entry                   mov     tmp1, par                       ' start of structure
                        rdlong  cmd, tmp1               wz      ' wait for cmd
        if_z            jmp     #entry

                        cmp     cmd, #1                 wz, wc  ' add?
        if_e            jmp     #addvals

                        ' check other commands here

                        jmp     #done                           ' invalid command
        

addvals               { add     tmp1, #4                        ' 4 for longs
                        rdlong  m, tmp1                      ' get 1st parameter from hub
                        add     tmp1, #4
                        rdlong  k1, tmp1
                        add     tmp1, #4
                        rdlong  k2, tmp1
                        add     tmp1, #4
                        rdlong  k3, tmp1
                        add     tmp1, #4
                        rdlong  k4, tmp1
                        add     tmp1, #4
                        rdlong  k5, tmp1
                        add     tmp1, #4
                        rdlong  k6, tmp1
                        add     tmp1, #4
                        rdlong  k7, tmp1
                        add     tmp1, #4
                        rdlong  k8, tmp1   }
                        
                        jmp     #mult

                        
retn
                       ' get 2nd parameter from hub                     ' add
                        add     tmp1, #4                        ' point to result in hub
                        wrlong  vRes, tmp1
                        add     tmp1, #4                        ' point to result in hub
                        wrlong  vRes2, tmp1
                        add     tmp1, #4                        ' point to result in hub
                        wrlong  DeltaTime, tmp1
                        jmp     #done                      ' write result to hub                   

mult
              mov       vRes, #0
              mov       vRes2, #0
              mov       w1, #0
              mov       Time1, cnt 
              mov       i,#32
:loop
              shr       v2, #1 wc
        if_c  add       vRes2, w1 
        if_c  add       vRes, v1  wc
        if_c  add       vRes2, #1 
              shl       w1, #1  
              shl       v1, #1  wc
        if_c  add       w1, #1     
              djnz      i,#:loop       
              mov       Time2, cnt 
              mov       DeltaTime, Time2
              sub       DeltaTime, Time1
           {   jmp       #retn    }

done                    mov     cmd, #0                         ' clear cmd
                        wrlong  cmd, par
                        
                        jmp     #entry                          ' wait for new cmd

teilmult
              add       tmp1, #4                       
              rdlong    v1, tmp1
              mov       j,#8 
:loop         
              add     tmp1, #4
              rdlong  v2, tmp1
              jmp       #mult
              add       tmp1, #32
              add       vRes, tRes1             wc
        if_c  add       tmp2, #1  wc
              add       vRes2, tmp wc
              mov       tmp2, #0
        if_c  mov       tmp2, #1                          
              wrlong    vRes, tmp1
              mov       tRes1, vRes2
              sub       tmp1, #32
              
              djnz      j,#:loop             
              

' -------------------------------------------------------------------------------------------------

acc1    long 0
acc2    long 0                                             
vRes    long 0
vRes2   long 0
tRes1   long 0  
Time1   long 0
Time2   long 0
DeltaTime    res 1
i    res 1
j    res 1 
tmp1                    res     1
tmp2                    res     1

cmd                     res     1
v1                    res     1
v2                    res     1
m                       res     1
w1                    res     1
w2                    res     1
k1      res   1
k2      res   1
k3      res   1
k4      res   1
k5      res   1
k6      res   1
k7      res   1
k8      res   1

                        fit     492

                      
dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}