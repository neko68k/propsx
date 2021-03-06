con

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

con
  RX1 = 31
  TX1 = 30
  IRTX = 13

  ' emulate master(PSX)
  iData = 0
  oCommand = 2
  oAttention = 4
  oClock = 6
  iAck = 8

  ' emulate slave(controller, memory card)
  oData = 8                '1
  iCommand = 6             '2
  iAttention = 4           '6
  iClock = 2               '7
  oAck = 0                 '9

con
  {IR_FREQ       = 40_000                                           ' modify to reduce power

  ' Sony IR codes
  IR_POWER      = %00001_0010101                                   
  IR_MUTE       = %00001_0010100
  IR_SLEEP      = %00001_0110110
  IR_ENTER      = %00001_0001011
  IR_UP         = %00001_1110100
  IR_DOWN       = %00001_1110101
  IR_LEFT       = %00001_0110100
  IR_RIGHT      = %00001_0110011
  IR_CENTER     = %00001_1100101
  IR_MENU       = %00001_1100000
  IR_VOL_UP     = %00001_0010010
  IR_VOL_DOWN   = %00001_0010011
  IR_CH_UP      = %00001_0010000
  IR_CH_DOWN    = %00001_0010001
  IR_RESET      = %00001_0010110
  IR_INPUT      = %00001_0100101
  IR_DISPLAY    = %00001_0111010
  IR_MTS_SAP    = %00001_0010111
  IR_JUMP       = %00001_0111011
  IR_FIVE       = %00001_0000100

  PSX_DUALSHOCK = $73
  PSX_STANDARD  = $41

  PAD_SELECT    =%0000_0001          
  PAD_L3        =%0000_0010
  PAD_R3        =%0000_0100
  PAD_START     =%0000_1000


  PAD_UP        =%0001_0000
  PAD_RIGHT     =%0010_0000
  PAD_DOWN      =%0100_0000
  PAD_LEFT      =%1000_0000

  PAD_L2        =%0000_0001          
  PAD_R2        =%0000_0010
  PAD_L1        =%0000_0100
  PAD_R1        =%0000_1000
  PAD_TRI       =%0001_0000
  PAD_CIR       =%0010_0000
  PAD_X         =%0100_0000
  PAD_SQU       =%1000_0000
   }
  cPsxcOff      = 1
  cPsxcOn       = 0
obj
  'irin  : "sircs_rx"                                         ' sircs input       *
  'irout : "sircs_tx"                                         ' sircs output      *
  BS2   : "BS2_Functions"                                    ' basic stamp 2 functions *
var
  BYTE Buttons[6] ' dual shock
  'BYTE Buttons[2] ' standard
  'BYTE Val
  BYTE Type[2]
  BYTE passback
pub main
  'ButtonBuf := 0
  'temp:=0
  
  BS2.Start(RX1, TX1)
  
  'irout.start(IRTX, IR_FREQ)                                    ' start sircs tx

  ' get LOCKID
  if(passback := LOCKNEW) == -1
    ' no locks available, fail somehow...
  ' start Master and SD cogs passing in LOCKID
  COGNEW(@SimBusSlave, @passback)
  REPEAT
    BS2.SEROUT_DEC(TX1, passback,9600,1,8)
    BS2.SEROUT_STR(TX1, string(13),9600,1,8)  
    'EmuMC   
    ReadController
    ' tv acts really strange if there is no delay between ir commands
    'waitcnt(2000 + cnt)


pub Sout (Value): locValue
    
    outa[oCommand]:=0                                          ' Data pin = 0
    outa[oClock]:=cPsxcOff                                          ' Set clock high 
       ' Send LSB first    

    WAITPEQ(%10, %10, 0)                             ' wait for ack to go high
    
    !outa[oClock]                                      ' clock low
    outa[oCommand] := Value                              ' Set output                                 
    locValue := (locValue >> 1) | (ina[iData] << 7)   ' get input
    !outa[oClock]                                      ' clock high
    !outa[oClock]
    outa[oCommand] := (Value>>1)                                                        
    locValue := (locValue >> 1) | (ina[iData] << 7)   
    !outa[oClock]                                      
         
    !outa[oClock]
    outa[oCommand] := (Value>>2)                                                         
    locValue := (locValue >> 1) | (ina[iData] << 7)
    !outa[oClock]
                                              
    !outa[oClock]
    outa[oCommand] := (Value>>3)                                                         
    locValue := (locValue >> 1) | (ina[iData] << 7)
    !outa[oClock]
                                              
    !outa[oClock]
    outa[oCommand] := (Value>>4)                            
    locValue := (locValue >> 1) | (ina[iData] << 7)
    !outa[oClock]
          
    !outa[oClock]
    outa[oCommand] := (Value>>5)                                      
    locValue := (locValue >> 1) | (ina[iData] << 7)
    !outa[oClock]
                                 
    !outa[oClock]
    outa[oCommand] := (Value>>6)                                       
    locValue := (locValue >> 1) | (ina[iData] << 7)
    !outa[oClock]
                                 
    !outa[oClock]
    outa[oCommand] := (Value>>7)                             
    locValue := (locValue >> 1) | (ina[iData] << 7)     
    !outa[oClock]

pub Sin (Value): locValue
    outa[oAck] := cPsxcOff
    outa[oData]:=cPsxcOff                                          ' Data pin = 0
    
       ' Send LSB first
    WAITPeq(0, |< iClock, 0)
    outa[oData] := Value                              ' Set output
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input
    'WAITPne(0, |< iClock, 0)  
    
                                     

    
    WAITPEQ(0, |< iClock, 0) 
    outa[oData] := (Value>>1)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input  
    'WAITPne(0, |< iClock, 0)

    

    
    WAITPEQ(0, |< iClock, 0)   
    outa[oData] := (Value>>2)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input
    'WAITPne(0, |< iClock, 0) 
   
                                                            

    
    WAITPEQ(0, |< iClock, 0)  
    outa[oData] := (Value>>3)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input
    'WAITPne(0, |< iClock, 0)

                                                             

    
    WAITPEQ(0, |< iClock, 0) 
    outa[oData] := (Value>>4)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input
    'WAITPne(0, |< iClock, 0)

                                

    
    WAITPEQ(0, |< iClock, 0) 
    outa[oData] := (Value>>5)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input                                 
    'WAITPEQ(iClock, iClock, 0)
                            
    WAITPEQ(0, |< iClock, 0) 
    outa[oData] := (Value>>6)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input 
    'WAITPne(0, |< iClock, 0)

                                           

    
    WAITPEQ(0, |< iClock, 0)
    outa[oData] := (Value>>7)
    WAITPne(0, |< iClock, 0)
    locValue := (locValue >> 1) | (ina[iCommand] << 7)   ' get input
    'WAITPne(0, |< iClock, 0)
   
                                 

     
     
                                                      

pub EmuMC | Val1, Val2, Val3, Val4, Val5, Val6, wait
  DIRA[oAck]~~
  DIRA[oData]~~
  DIRA[iCommand..iClock]~
  OUTA[oAck] := cPsxcOff
  OUTA[oData] := cPsxcOff

  'OUTA[22]:=0
  WAITPne(0, |< iAttention, 0)
  WAITPeq(0, |< iAttention, 0)
  wait := 1
  'OUTA[22]:=1
  
  'DIRA[oData]~
  Val1:=Sin($00)
  'DIRA[oData]~~
  'BS2.SEROUT_DEC(TX1, !Val&255,9600,1,8)
  'BS2.SEROUT_DEC(TX1, Val,9600,1,8)
  'BS2.SEROUT_STR(TX1, string(13),9600,1,8)
  outa[oAck] := cPsxcOn
  waitcnt(wait+cnt)
  outa[oAck] := cPsxcOff
  'IF !Val1&255==1
    
    Val2:=Sin(PSX_STANDARD)
    outa[oAck] := cPsxcOn
    waitcnt(wait+cnt)
    outa[oAck] := cPsxcOff
    
    Val3:=Sin($5A)
    outa[oAck] := cPsxcOn
    waitcnt(wait+cnt)
    outa[oAck] := cPsxcOff

    Val4:=Sin($00)
    outa[oAck] := cPsxcOn
    waitcnt(wait+cnt)
    outa[oAck] := cPsxcOff

    Val5:=Sin($00)
    outa[oAck] := cPsxcOn
    waitcnt(wait+cnt)
    outa[oAck] := cPsxcOff

    Val6:=Sin($00)
    'outa[oAck] := cPsxcOff
    
    
  {ELSEIF !Val1&255==$81
    BS2.SEROUT_STR(TX1, string(13),9600,1,8)
    BS2.SEROUT_STR(TX1, string("Check for MC"),9600,1,8)
    BS2.SEROUT_STR(TX1, string(13),9600,1,8)
    BS2.SEROUT_STR(TX1, string(13),9600,1,8) }
  {ELSE
    BS2.SEROUT_STR(TX1, string(13),9600,1,8)
    BS2.SEROUT_STR(TX1, string("Error: Unknown code"),9600,1,8)
    BS2.SEROUT_STR(TX1, string(13),9600,1,8) }

  {BS2.SEROUT_DEC(TX1, !Val1&255,9600,1,8)
  BS2.SEROUT_STR(TX1, string(13),9600,1,8)
  BS2.SEROUT_DEC(TX1, !Val2&255,9600,1,8)
  BS2.SEROUT_DEC(TX1, !Val3&255,9600,1,8)
  BS2.SEROUT_DEC(TX1, !Val4&255,9600,1,8)
  BS2.SEROUT_DEC(TX1, !Val5&255,9600,1,8)
  BS2.SEROUT_DEC(TX1, !Val6&255,9600,1,8)
  BS2.SEROUT_STR(TX1, string(13),9600,1,8)} 
  'OUTA[22]:=1
  'OUTA[23]:=0

pub ReadController | Val, Type0, Type1, Buttons0, Buttons1, Buttons2, Buttons3, Buttons4, Buttons5 


  DIRA[iAck..iData]~
  DIRA[oAttention..oCommand]~~
  OUTA[oAttention] := cPsxcOff
  OUTA[oClock] := cPsxcOff
  OUTA[oCommand] := cPsxcOff
  ' Get the controller's attention  
  OUTA[oAttention] := cPsxcOn

  ' send  start cmd
  '
  Sout($01)                    ' ask for id
  WAITPEQ(%00, %10, 0)         ' wait for ACK to go low

  Type0:=Sout($42)             ' get id and send data req
  WAITPEQ(%00, %10, 0)


  IF Type0==PSX_STANDARD
    Type1:=Sout($00)           ' get ready 
    WAITPEQ(%00, %10, 0)
     
    Buttons0:=Sout($50)        ' get some buttons
    WAITPEQ(%00, %10, 0)
       
    Buttons1:=Sout($50)        ' get the rest of the buttons
                                                           ' last data doesn't have an ACK
                                                           ' PSX assumes controller is done or gone after a delay
    Buttons2:=0                                            ' make sure analog stuff is zeroed after mode shift
    Buttons3:=0
    Buttons4:=0
    Buttons5:=0

  ELSEIF Type0==PSX_DUALSHOCK
    Type1:=Sout($00)          ' get ready
    WAITPEQ(%00, %10, 0)      ' wait for ACK                            
     
    Buttons0:=Sout($00)       ' get some buttons
    WAITPEQ(%00, %10, 0)
       
    Buttons1:=Sout($00)       ' get the rest of the buttons
    WAITPEQ(%00, %10, 0)

    Buttons2:=Sout($00)       ' get right stick x axis
    WAITPEQ(%00, %10, 0)

    Buttons3:=Sout($00)       ' get right stick y axis
    WAITPEQ(%00, %10, 0)

    Buttons4:=Sout($00)       ' get left stick x axis
    WAITPEQ(%00, %10, 0)

    Buttons5:=Sout($00)       ' get left stick y axis
    
                                                           

  OUTA[oAttention] := cPsxcOff
  OUTA[oClock] := cPsxcOff

  Buttons0:=!Buttons0&255
  Buttons1:=!Buttons1&255
  Buttons2:=!Buttons2&255
  Buttons3:=!Buttons3&255
  Buttons4:=!Buttons4&255
  Buttons5:=!Buttons5&255

  {
  BS2.SEROUT_DEC(TX1, Type0,9600,1,8)
  BS2.SEROUT_DEC(TX1, Type1,9600,1,8)
  BS2.SEROUT_STR(TX1, string(" "),9600,1,8)
  BS2.SEROUT_DEC(TX1, Buttons0,9600,1,8)  
  BS2.SEROUT_DEC(TX1, Buttons1,9600,1,8)
  BS2.SEROUT_DEC(TX1, Buttons2,9600,1,8)
  BS2.SEROUT_DEC(TX1, Buttons3,9600,1,8)
  BS2.SEROUT_DEC(TX1, Buttons4,9600,1,8)
  BS2.SEROUT_DEC(TX1, Buttons5,9600,1,8)
  BS2.SEROUT_STR(TX1, string(13),9600,1,8)
  }
   
  ' dpad and start, select, analog pushbuttons
  ' Select
  {IF Buttons0&PAD_SELECT
    irout.tx(IR_INPUT, 12, 5)
    
    RETURN
  ' Left analog pushbutton
  'IF Buttons[0]&PAD_L3
  '  irout.tx(IR_POWER, 12, 5)
  '  RETURN
  ' Right analog pushbutton
  'IF Buttons[0]&PAD_R3
  '  irout.tx(IR_DISPLAY, 12, 5)
  '  RETURN
  ' Start
  ELSEIF Buttons0&PAD_START
    'irout.tx(IR_DISPLAY, 12, 5)
    'irout.tx(IR_FIVE, 12, 5)
    'irout.tx(IR_VOL_DOWN, 12, 5)
    irout.tx(IR_POWER, 12, 5)
    
    RETURN
  ' Up
  ELSEIF Buttons0&PAD_UP
    irout.tx(IR_UP, 12, 5)
    
    RETURN
  ' Right
  ELSEIF Buttons0&PAD_RIGHT
    irout.tx(IR_RIGHT, 12, 5)
    
    RETURN
  ' Down
  ELSEIF Buttons0&PAD_DOWN
    irout.tx(IR_DOWN, 12, 5)
    
    RETURN
  ' Left
  ELSEIF Buttons0&PAD_LEFT
    irout.tx(IR_LEFT, 12, 5)
    
    RETURN

  
  ' symbols and shoulders
  ' L2
  IF Buttons1&PAD_L2
    irout.tx(IR_VOL_UP, 12, 5)
    
    RETURN
  ' R2
  ELSEIF Buttons1&PAD_R2
    irout.tx(IR_CH_UP, 12, 5)
    
    RETURN
  ' L1
  ELSEIF Buttons1&PAD_L1
    irout.tx(IR_VOL_DOWN, 12, 5)
    
    RETURN
  ' R1
  ELSEIF Buttons1&PAD_R2
    irout.tx(IR_CH_DOWN, 12, 5)
    
    RETURN

  ' /\  
  ELSEIF Buttons1&PAD_TRI
    irout.tx(IR_MENU, 12, 5)
    
    RETURN
  ' O
  ELSEIF Buttons1&PAD_CIR
    irout.tx(IR_MTS_SAP, 12, 5)
    
    RETURN
  ' X
  ELSEIF Buttons1&PAD_X
    irout.tx(IR_ENTER, 12, 5)
    
    RETURN
  ' []
  ELSEIF Buttons1&PAD_SQU
    irout.tx(IR_JUMP, 12, 5)
    
    RETURN
    }
{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
DAT

              org 0

SimBusSlave            ' do stuff!
              rdbyte       loclock, PAR
              mov       t1, #1                  wz
              muxnz     dira, outpinmask                ' Set outputs
              wrbyte       PAR, #0            
              

              

              muxnz     dira, debugpinmask
:NewCmd              
              mov       Data, #$0
:WaitForAtt
              muxnz     outa, outpinmask                ' set data and ack HIGH
              'muxnz     dira, debugpinmask
              waitpeq   BUS_ON, #%10000                      ' wait for attention LOW
              mov       Bits, #8                          ' we process 8 bits both dirs
              
              'test      t1, #1                  wz
              'muxc      outa, t1'

:loop                            
              waitpeq   BUS_ON, #%100                      ' wait for clock LOW
              
              ' shift out
              'mov     t3,             arg4              ''          Load t3 with DataValue
              test    Data,             #1      wc        ''          Test LSB of DataValue
              muxc    outa,             #%1_0000_0000                ''          Set DataBit HIGH or LOW
              shr     Data,             #1                ''          Prepare for next DataBit
              'call    #PostClock                        ''          Send clock pulse
              'djnz    t4,             #LSB_Sout         ''          Decrement t4 ; jump if not Zero
              'mov     t1,             #1      wz        ''          Force DataBit HIGH
              'muxnz   outa,           t1


              waitpne   BUS_ON, #%100                     ' wait for clock HIGH
              
              ' shift in
              mov     t1,             #%0100_0000
              test    t1,             ina       wc      ''          Read Data Bit into 'C' flag
              rcr     Cmd,             #1                ''          rotate "C" flag into return value
              'djnz    t4,             #LSBPOST_Sin      ''          Decrement t4 ; jump if not Zero
              'mov     t4,             #32               ''     For LSB shift data right 32 - #Bits when done
              'sub     t4,             #8

              
        djnz  Bits, #:loop
              shr     Cmd,            24
              ' kill some time
              ' ack
              
              waitpeq   BUS_OFF, #%100

              WRBYTE    Cmd, PAR
               
              ' kill some more time
              ' probably write to hub memory or before ack
              ' unack

              ' need to check att state and how many BYTEs we've read from
              ' the controller per the specs

              'test      t1, #1                  wz
              'muxnc      outa, t1              
              'mov     outa, outpinmask
'              mov       t1, #1                  wz

              muxnz      outa, debugpinmask
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              nop
              mov       t1, #1                  wz
              muxz      outa, #1              
              test active, #1   wc
        if_nc  jmp #:ConSend
              cmp Cmd, #1       wz
              ' jmp to command specific command handler 
        if_nz  jmp #:CmdConBegin
              cmp Cmd, #66     wz
        if_nz  jmp #:CmdConID      

              
              'muxz      outa, debugpinmask
              
        jmp #:NewCmd
                                          
        ' handle command stuff here
:CmdConBegin
              'mov       t1, #1                  wz
              muxz      outa, debugpinmask
              'mov Data, #$41
              'unack
              'mov       t1, #1                  wz
              'muxnz     outa, outpinmask
              jmp #:WaitForAtt
:CmdConID

              'mov Data, #$5A        
              mov active, #1
              mov bytes, #2
              'unack
              'mov       t1, #1                  wz
              muxz     outa, debugpinmask
              jmp #:WaitForAtt
:ConSend
              mov Data, #$FF
              sub bytes, #1      wz
        if_z  mov active, 0
        if_z  jmp #:NewCmd
              'unack
              mov       t1, #1                  wz
              'muxz     outa, debugpinmask
              
        jmp #:WaitForAtt
DAT
nothing       long 0
outpinmask    long %0000_0001_0000_0001
inpinmask     long %0000_0000_0101_0100
debugpinmask  long %0000_0000_0010_0000_0000_0000_0000_0000



PSX_DUALSHOCK long $73
PSX_STANDARD  long $41
PAD_SELECT    long %0000_0001          
PAD_L3        long %0000_0010
PAD_R3        long %0000_0100
PAD_START     long %0000_1000
 
PAD_UP        long %0001_0000
PAD_RIGHT     long %0010_0000
PAD_DOWN      long %0100_0000
PAD_LEFT      long %1000_0000
 
PAD_L2        long %0000_0001          
PAD_R2        long %0000_0010
PAD_L1        long %0000_0100
PAD_R1        long %0000_1000
PAD_TRI       long %0001_0000
PAD_CIR       long %0010_0000
PAD_X         long %0100_0000
PAD_SQU       long %1000_0000
BUS_ON        long 0
BUS_OFF       long %100



DAT
loclock RES 1
command RES 1

active  RES 1

t1      RES 1
bytes      RES 1
Bits    RES 1
Cmd     RES 1
Data    RES 1
{
  oData = 8                '1
  iCommand = 6             '2
  iAttention = 4           '6
  iClock = 2               '7
  oAck = 0                 '9
  }