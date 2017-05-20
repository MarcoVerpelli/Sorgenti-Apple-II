***********************
* STEPPER             *
* BY WAYNE EASTWOOD   *
* COPYRIGHT (C) 1987  *
* BY MICROSPARC, INC. *
* CONCORD, MA 01742   *
***********************

* My 0-page use
CH       =     $24        ;cursor position locations
CV       =     $25
LMNEM    =     $2C        ;used in opcodes disassembly
RMNEM    =     $2D
LENGTH   =     $2F        ;instruction lenght - 1
PC       =     $3A        ;PC used by PRADR1
A1       =     $3C        ;loc. of 16-bit # on entry (####[Y])

* Constant definitions

CR       =     $8D        ;C/R
SPACE    =     $A0        ;ASCII space

* System and DOS calls

STACK    =     $0100      ;6502 stack
HOOKUP   =     $03EA      ;DOS hook up
YVECTOR  =     $03F8      ;jump to here on ctrl-Y
DOSINOUT =     $AA59      ;48K RAM DOS I/O values storage
KYBOARD  =     $C000      ;key input
STROBE   =     $C010      ;key strobe
PRODOS   =     $BF00
VECTIN   =     $BE32
VECTOUT  =     $BE30

* Monitor calls

INSDS2   =     $F88E      ;look up opcode info
PRADR1   =     $F910      ;print 16-bit address (mid-routine)
PRBLNX   =     $F948      ;print 3 blanks
MNEML    =     $F9C0      ;mnemonics table
MNEMH    =     $FA00
SETTXT   =     $FB39      ;txt mode & full windows
VTAB     =     $FC22      ;cursor VTAB
RDKEY    =     $FD0C      ;read key
CROUT    =     $FD8E      ;output C/R
PRYX3    =     $FD99      ;print 16-bit at X,Y
PRBYTE   =     $FDDA      ;print hex in A
COUT     =     $FDED      ;char out
SETINV   =     $FE80      ;set screen inverse
SETNORM  =     $FE84      ; "     "   normal
OUTPORT  =     $FE95      ;reset I/O
MON      =     $FF69      ;reenter monitor

         XC               ;siamo il //c

* Assemble one in high memory and one in low memory
* to allow tracing programs at various locations

         ORG   $8F00

* Enters here on BRUN or monitor G
* to set up [Y] vector & initialize
* program parameters

ENTER    LDA   #$4C       ;'JMP' is stored for ctrl-Y
         STA   YVECTOR
         LDA   #<STEP     ;point to STEPPER address
         STA   YVECTOR+1
         LDA   #>STEP
         STA   YVECTOR+2
         LDX   #10        ;clear all information register
ENTER10  STZ   aSAVE,X    ;era LDA #0, STA aSAVE,x
         DEX
         BPL   ENTER10
         DEC   sSAVE
         RTS

* Enter here: ADRS[Y] = step at new PCNT, save current 0-page
*                 [Y] = step at current PCNT, use prev 0-page

STEP     TXA              ;if X=0, then no ADRS
         BEQ   STEPLOOP   ;go directly to main routine
         JSR   ZSAVE0     ;new ADSR, so save current 0-page
         LDX   #5         ;clear register & run flag
         JSR   ENTER10
         LDA   A1         ;put new address into PCNT
         STA   PCNT       ;A1 set from monitor routine
         LDA   A1+1       ;  when reading [Y]
         STA   PCNT+1     ;fall into main tracing routine

* Main tracing routine:
* 1) Display memory and stack per user direction
* 2) Display current register & next instruction
* 3) Seek user input for step/run, register change etc.
* 4) Perform next instruction
* 5) Return to 1) above

* 1) Display memory and stack per user direction

STEPLOOP JSR   SETTXT     ;always start with new screen
         JSR   CROUT      ;insure new line

* Eliminato l'invio di C/R a video, gestito altrove per
* risolvere il problema dell'esecuzione di BRK che provocava
* un formato video non corretto

*        JSR   COUT+3     ;2 for screen for readability

         LDX   mCOUNT     ;display any memory?
         BEQ   SL10       ;no
         JSR   DSPMEM     ;display memory
SL10     LDX   tFLAG      ;dispaly stack
         BEQ   SL40       ;no
         LDX   sSAVE      ;get current stack location
         INX              ;at bottom?
         BEQ   SL40       ;yes, none to see
         LDY   #10        ;11 max
SL20     LDA   STACK,X    ;display values separated w/spaces
         JSR   PRBYTE
         LDA   #SPACE
         JSR   COUT
         INX              ;more stack?
         BEQ   SL30       ;no
         DEY              ;more list?
         BPL   SL20       ;yes
SL30     JSR   PRBLNX     ;flush with 3 blanks to tab printer
         DEY              ;  (not noticed on screen display)
         BPL   SL30
         LDA   #CR        ;new line for screen but not printer
         JSR   COUT+3

* 2) Display current register & next instruction

SL40     JSR   DSPREG     ;display current register
         LDX   PCNT       ;print PCNT as hex followed by '-'
         LDY   PCNT+1
         STX   PC         ;save for disassembly by PRADR1
         STY   PC+1
         JSR   PRYX3      ;print
         JSR   ZRESTORE   ;restore source 0-page
         LDX   #2         ;get next instruction (3-bytes max)
SL50     JSR   PRGGET     ;  & store for program reference
         STA   NXTINST,X  ;  at NXTINST, NXTINST+1, NXTINST+2
         DEX
         BPL   SL50
         JSR   ZSAVE      ;return my own 0-page
         LDA   #$EA       ;clear execution area with
         STA   EXECUTE+1  ;  'NOP' ($EA) instructions
         STA   EXECUTE+2
         LDA   NXTINST    ;load opcode of instr. & use monitor
         JSR   INSDS2     ;  to find format, len, & index
         LDX   #3         ;three chars in mnemonic
         TAY              ;mnemonic table index
         LDA   MNEML,Y    ;fetch 3-char mnemonic
         STA   LMNEM      ;  (packed in 2 bytes)
         LDA   MNEMH,Y    ;(this is an imitation of the Mon.
         STA   RMNEM      ;  rout. except we disass. the
SL60     LDA   #0         ;  opcode only w/o displaying hex
         LDY   #5         ;  code as well and mod. the spacing)
SL70     ASL   RMNEM      ;shift 5 bits of chr into A
         ROL   LMNEM
         ROL
         DEY
         BNE   SL70
         ADC   #"? ;carry clear, add '?' offset
         JSR   COUT       ;print it
         CMP   #"? ;exit on unknown opcode '???'
         BNE   SL80
         JSR   SETINV         ;display code
         LDA   NXTINST
         JSR   PRBYTE
         JSR   SETNORM
         BRA   INTBRK10   ;exit (era JMP)
SL80     DEX
         BNE   SL60
         LDA   #SPACE     ;one blank
         JSR   COUT
         LDY   LENGTH     ;prepare to enter norm. Mon. stream
         LDX   #6         ;  to print the address field
         JSR   PRADR1     ;enter

* 3) Seek user input for step/run, register change, etc.

         JSR   RESPOND    ;read user input

* 4) Perform next instruction

         LDX   sSAVE      ;ready to go, put on source stack
         TXS
         LDA   NXTINST    ;get opcode

* Normally, instr. fall through to PERFORM. However, we
* must interpret BRK, RTI, RTS, JSR, JMP and JMP (XXXX)
* to maintain control of program. Relative branching is
* controlled at PERFORM

* Inserito anche interpretazione di JMP (XXXX,X)

         BEQ   INTBRK     ;'BRK'
         CMP   #$40       ;'RTI'?
         BEQ   INTRTI
         CMP   #$60       ;'RTS'?
         BEQ   INTRTS
         CMP   #$20       ;'JSR'?
         BNE   SL90       ;no
         LDX   jFLAG      ;yes, run entire routine or step?
         BEQ   INTJSR     ;continue single step
SL90     CMP   #$4C       ;'JMP'?
         BEQ   INTJMP
         CMP   #$6C       ;indirect JMP?
         BEQ   INTJMPI

* Controlla se $7C = JMP (XXXX,X)

         CMP   #$7C       ;JMP indiretto, X?
         BEQ   INTJMPIX

* Inserito un salto a subroutine per problemi di spazio
* ora riconosce anche Branch Always

PERFORM  JSR   CHKBRC     ;vede se e' istruzione di branch

         BEQ   SL110      ;  the offset branch into our prgm
SL100    LDA   NXTINST,Y  ;move all necess., other 'NOP'
SL110    STA   EXECUTE,Y
         DEY
         BPL   SL100
         JSR   ZRESTORE   ;put on source 0-page
         LDA   pSAVE      ;restore all register
         PHA
         LDA   aSAVE
         LDX   xSAVE
         LDY   ySAVE
         PLP

EXECUTE  DS    3          ;execute the instruction

         JMP   NOBRNCH    ;if no branch

* Branch if taken falls here always.  PCNT is adjusted
* then we return to STEPLOOP for next instruction

         JSR   ZSAVE      ;restore my 0-page
         CLD              ;restore correct conditions
         CLC
         LDA   NXTINST+1  ;forward or backward branch?
         BPL   XQT10      ;forward
         DEC   PCNT+1     ;backward, adjust prgm counter
XQT10    JSR   ADDPCNT    ;adjust value of prgm counter
         JMP   UPDATE     ;get new prgm counter & step again

* Opcode interpretation routines

INTBRK   JSR   DSPREG     ;display register
INTBRK10 JMP   EXIT       ;exit program

INTRTI   TSX              ;simulate 'RTI'
         CPX   #$FD       ;enough on stack?
         BCS   INTBRK10   ;no
         PLA              ;pull processor status
         STA   pSAVE      ;  & continue
INTRTS   TSX              ;simulate 'RTS'
         CPX   #$FE       ;enough on stack?
         BCS   INTBRK10   ;no
         PLA              ;pull off return address
         STA   PCNT       ;put on prgm counter
         PLA
         STA   PCNT+1
         TSX              ;save stack
         STX   sSAVE
         BRA   UPDATE     ;next prgm counter & step (era JMP)

INTJSR   LDA   PCNT       ;increment prgm counter by 2
         ADC   #1         ;  imitating normal 6502 operation
         TAY              ;since carry was set on entry we save
         LDA   PCNT+1     ;  SOME CODE BY ADDING 1 plus carry
         ADC   #0         ;  instead of CLC then adding 2
         PHA              ;and push on stack
         PHY              ;era TYA, PHA
         TSX              ;save & continue as 'JMP'
         STX   sSAVE
INTJMP   LDA   NXTINST+1  ;find new PC by looking at
         PHA              ;  opcode address field
         LDA   NXTINST+2
         PHA
         BRA   INTJMP10   ;era JMP

* Interpreta JMP (XXXX,X). Come JMP (XXXX) solo che tiene
* conto del contenuto del registro X al momento
* dell'esecuzione

INTJMPIX LDX   xSAVE       ;riprende contenuto registro X
         BRA   INTJMP20    ;prosegue come JMP (XXXX)

INTJMPI  LDX   #0          ;spostato da dove era
INTJMP20 LDA   NXTINST+1   ;find indirect address by finding
         STA   PCNT        ;  the contents of the address
         LDA   NXTINST+2   ;  specified in the address field
         STA   PCNT+1
         JSR   ZRESTORE    ;put back ZP in case adrs is there

* Spostato all'inizio per permettere il caricamento con
* l'offset di JMP (XXXX,X)

*        LDX   #0          ;find contents of address
         JSR   PRGGET
         PHA
         INX
         JSR   PRGGET
         PHA
         JSR   ZSAVE      ;swap 0-page again
INTJMP10 PLA              ;install new address
         STA   PCNT+1
         PLA
         STA   PCNT
         JMP   STEPLOOP   ;continue

* Add PCNT to A, carry clear or set prior to entry

ADDPCNT  ADC   PCNT       ;if carry set, result 1 greater
         STA   PCNT
         BCC   ADDP10
         INC   PCNT+1
ADDP10   RTS

* All non-interpreted instr. that do not branch come here

NOBRNCH  STA   aSAVE      ;operation completed, save stuff
         STX   xSAVE
         STY   ySAVE
         PHP
         PLA
         STA   pSAVE
         TSX
         STX   sSAVE
         JSR   ZSAVE      ;return my 0-page
         CLD              ;will cause many problems if set!
UPDATE   SEC              ;add LENGTH + 1 (SEC) to PC
         LDA   LENGTH
         JSR   ADDPCNT    ;add them
         JMP   STEPLOOP   ;continue

* Possible user responses

REGNAM   ASC   "AXYS"
PROCNAM  HEX   CE,D6,E5,E2,C4,C9,DA,C3 ;NVebDICZ (lower-case not used)
PSUDNAM  ASC   "RJPTEK"
         HEX   85,8B      ;ctrl-E, ctrl-K
PROMPT   INV   " CZIDB.VN  S  Y  X  A   ]K[K ]E[E R JPTQ"

* Inserito C/R prima del prompt per risolvere
* il problema del BRK

         HEX   8D         ;C/R per il video

* Cursor tab for user responses

REGTAB   HEX   13,16,19,1C
PROCTAB  HEX   1F,20,21,22,23,24,25,26
PSDTAB   HEX   03,02,01

* Masks for pSAVE

ORMASK   HEX   80,40,20,10,08,04,02,01

INDEX    DS    1          ;temporary index for user entry
DFLAG    DS    1          ;multy-purpose flag
NXTINST  DS    3          ;hold next instruction
aSAVE    DS    1          ;register save
xSAVE    DS    1
ySAVE    DS    1
sSAVE    DS    1
pSAVE    DS    1
rFLAG    DS    1          ;run flag
jFLAG    DS    1          ;JSR flag
pFLAG    DS    1          ;printer flag
tFLAG    DS    1          ;stack flag
mCOUNT   DS    1          ;number of memory loc. (mCOUNT+1)/2
bCOUNT   DS    1          ; "   "  brk. points (bCOUNT+1)/2

MEMAREA  DS    2*10-1     ;space for 10 memory locations
BRKAREA  DS    2*5-1      ;space for 5 breakpoints

PRGZ     DS    $56        ;source program 0-page storage
MYZ      DS    $56        ;my 0-page storage
PRGDOS   DS    4          ;program DOS print parameters
MYDOS    DS    4          ;my DOS print parameters

* Display current register

* Modificata lunghezza prompt perche' inserito C/R

DSPREG   LDX   #40        ;prompt for screen only (era 39)
DSPR10   LDA   PROMPT,X
         JSR   COUT+3
         DEX
         BPL   DSPR10
         LDA   #">
         JSR   COUT+3
         LDX   #2         ;examine flags
DSPR20   LDA   jFLAG,X
         BEQ   DSPR21
         JSR   SETINV     ;display in inverse if set
DSPR21   LDA   PSUDNAM+1,X
         JSR   COUT+3     ;display flag letter
         JSR   SETNORM
         DEX
         BPL   DSPR20
         LDA   #19        ;tab right on screen
         STA   CH
         LDX   #0
DSPR30   LDA   aSAVE,X    ;get value of register
         JSR   PRBYTE     ;display
         LDA   #SPACE
         JSR   COUT
         INX
         CPX   #4         ;done?
         BCC   DSPR30     ;no
         LDA   pSAVE      ;now display processor status
         TAY
         LDA   #%10000000 ;mask, interested in bits here
         STA   A1         ;temporary storage
DSPR40   TYA              ;restore pSAVE value
         AND   A1         ;and w/ current mask
         BEQ   DSPR50     ;0 value
         LDA   #"1 ;on, display '1'
         HEX   2C         ;'BIT XXXX' -- falls through
DSPR50   LDA   #"0 ;off, display '0'
         JSR   COUT
         LSR   A1         ;shift mask -->
         BNE   DSPR40     ;do for all bits
         LDA   #CR        ;for screen
         JSR   COUT+3
         LDA   #"> ;next line (mark for printer)
         JMP   COUT

* Stop loop and get user input

RESPOND  LDA   rFLAG      ;in run mode?
         BEQ   RS10       ;no
         JSR   BRKCHK     ;yes, check for breakpoint
         BCS   RS05       ;found one so stop
         LDA   KYBOARD    ;in run mode, any key stops
         BPL   RS70       ;else exit w/out checking further
         STA   STROBE     ;clear
RS05     STZ   rFLAG      ;no more run (era LDA #0, STA rFLAG)
RS10     LDA   #23        ;position cursor
         STA   CV
         LDA   #17
         STA   CH
         JSR   VTAB
         JSR   RDKEY      ;get response from user
         CMP   #SPACE     ;next step?
         BEQ   RS70       ;yes, exit
         CMP   #"Q ;quit?
         BNE   RS20
         BRA   EXIT0      ;exit one level into JSR's (era JMP)

* Check if a register response A,X,Y, or S

RS20     LDY   #3
RS30     CMP   REGNAM,Y
         BEQ   RS60R      ;yes
         DEY
         BPL   RS30

* Check if one of the processor status bits N,V,D,I,Z, or C

         LDY   #7
RS40     CMP   PROCNAM,Y
         BEQ   RS60P      ;yes
         DEY
         BPL   RS40

* Check if one of the presudo ops R,E,[E],K,[K],T,P, or J

         LDY   #7
RS50     CMP   PSUDNAM,Y
         BEQ   RS60S      ;yes
         DEY
         BPL   RS50
         BMI   RS10       ;no correct response

* Handle input: carry set if to proceed to next instruction

RS60S    JSR   DOPSUEDO   ;handle pseudo ops
         BCC   RS10       ;back for more (not 'R' or step)
         BCS   RS70       ;continue to next step
RS60P    JSR   DOPROC     ;processor bits
         BRA   RS10       ;always back for more (era JMP)
RS60R    JSR   DOREG      ;register bytes
         BCC   RS10       ;no step
RS70     RTS

DOREG    STY   INDEX      ;alter register, Y tells which one
R10      JSR   SETINV     ;for emphasis
         JSR   ONSCREEN   ;insure screen only
         LDY   INDEX      ;restore index
         LDA   REGTAB,Y   ;get proper tab for display
         STA   CH
         LDA   aSAVE,Y    ;display current value
         JSR   PRBYTE
         LDA   pFLAG      ;return to specified output device
         AND   #1         ;1 or 0
         JSR   DFLTOUT    ;restore current output
         DEC   CH         ;put cursor on top of image
         JSR   SETNORM
         JSR   RDKEY      ;change it as desired
         CMP   #SPACE     ;step?
         BNE   R30        ;no
R20      RTS              ;carry set if space
R30      CMP   #"Q ;quit
         BNE   R40        ;no
         PLA              ;exit 2 deep in JSR's
         PLA
EXIT0    PLA
         PLA
EXIT     JSR   ZRESTORE   ;restore 0-page
         JMP   MON        ;exit to monitor

R40      EOR   #"0 ;determines if hex digit
         CMP   #$0A       ;digits 0-9 result in value 0-9 so
         BCC   R50        ;  carry clear means yes
         ADC   #$88       ;digits $A-$F to $71-$76, add
         CMP   #$FA       ;  $89 (w/carry) to push to $FA-$FF
         BCC   R20        ;no, exit for more input
R50      LDY   #3         ;lower nibble of A holds $x0-$xF
         ASL              ;move low nibble to high
         ASL
         ASL
         ASL
         LDX   INDEX      ;where does this go?
R60      ASL              ;move into low nibble of storage
         ROL   aSAVE,X    ;  & move low nibble to high
         DEY
         BPL   R60
         BRA   R10        ;era BMI

DOPROC   STY   INDEX      ;toggle stat bit, Y points to bit
P10      JSR   SETINV
         LDY   INDEX      ;position cursor
         LDA   PROCTAB,Y
         STA   CH
         LDA   pSAVE      ;load entire status & mask
         AND   ORMASK,Y   ;  for desired bit
         BEQ   P20        ;it's a 0, convert to 1
         LDA   #"0 ;it's a 1, convert to 0
         HEX   2C         ;'BIT XXXX' falls through 3 bytes
P20      LDA   #"1
         JSR   COUT+3     ;display on screen only
         JSR   SETNORM
         LDY   INDEX
         CMP   #"0-$80 ;update status bit (MSB
         BEQ   P30        ;  cleared due to SETINV)
         LDA   ORMASK,Y   ;change 0 to 1
         ORA   pSAVE
         BRA   P40        ;era BNE
P30      LDA   ORMASK,Y
         EOR   #$FF       ;convert for ANDing
         AND   pSAVE      ;clear a bit
P40      STA   pSAVE
         RTS

DOPSUEDO TYA              ;handle all other codes
         BNE   PS1        ;not run flag
         INC   rFLAG      ;'R', so set flag
         SEC              ;run so exit
         RTS
PS1      CMP   #4         ;J, P, or T flags?
         BCS   PSD1       ;no, some sort of display option
         TAX              ;index for correct flag
         LDA   #$FF       ;toggle flag
         EOR   rFLAG,X    ;X=1, 2, or 3
         STA   rFLAG,X
         BEQ   PSF1       ;now update display, 0=off
         JSR   SETINV     on shown in inverse
PSF1     DEC   CV         ;move cursor
         JSR   VTAB
         LDA   PSDTAB-1,X ;get cursor tab (X is 1 too large)
         STA   CH
         LDA   PSUDNAM,X  ;get display letter
         JSR   COUT+3     ;screen only
         JSR   SETNORM
         CPX   #2         ;printer toggle requested?
         BNE   PSF4       ;no
         LDA   pFLAG      ;yes, get current value
         AND   #1         ;make a 1 or 0
         BNE   DFLTOUT    ;turn printer on
         JSR   CROUT      ;rtn to screen, clr any prtr buff
ONSCREEN LDA   #0         ;PR#0
DFLTOUT  JSR   OUTPORT    ;set up hooks
         LDA   PRODOS
         CMP   #$4C
         BNE   HOOKDOS
         LDA   $36
         STA   VECTOUT
         LDA   $37
         STA   VECTOUT+1
         BRA   PSF4       ;era JMP
HOOKDOS  JSR   HOOKUP     ;tell DOS
PSF4     CLC              ;return for more user input
         RTS

PSD1     CMP   #7         ;handle display options, ctrl-K?
         BNE   PSD2       ;no
         STZ   bCOUNT     ;clear all breakpoints (era LDA #0, STA bCOUNT)
         BRA   PSF4       ;era BEQ
PSD2     CMP   #6         ;clear memory (ctrl-E)?
         BNE   PSD3       ;no
         STZ   mCOUNT     ;clear all (era LDA #0, STA mCOUNT)
         BRA   PSF4       ;era BEQ
PSD3     CMP   #5         ;set breakpoint (K)?
         BEQ   BSET       ;yes
         BRA   INPMEM     ;display addresses & add to list (era JMP)
BSET     JSR   ONSCREEN   ;set up for screen only
         JSR   CROUT
         LDX   bCOUNT     ;bCOUNT=# of entries*2+1
         BEQ   BS20       ;no entries/no display
         DEX
BS10     LDA   BRKAREA,X  ;stored low/high
         JSR   PRBYTE     ;display
         DEX
         LDA   BRKAREA,X
         JSR   PRBYTE
         LDA   #SPACE     ;separate
         JSR   COUT
         DEX
         BPL   BS10
BS20     JSR   CROUT      ;done with display
         LDX   bCOUNT     ;full?
         CPX   #10
         BCS   BS30       ;yes, can't add any
         JSR   GETDIG     ;get address
         LDX   bCOUNT
         LDA   DFLAG      ;any entry?
         BEQ   BS30       ;no
         LDA   A1         ;put new address in memory
         STA   BRKAREA,X
         INX
         LDA   A1+1
         STA   BRKAREA,X
         INX
         STX   bCOUNT
BS30     LDA   pFLAG      ;restore output device
         AND   #1
         JSR   DFLTOUT
         PLA              ;pull off JSR's
         PLA
         PLA
         PLA
         JMP   STEPLOOP   ;redo current line

* Display routines: INPMEM = display then add
*                   DSPMEM = display only

INPMEM   JSR   ONSCREEN   ;set up for screen only
         JSR   CROUT
         LDA   #0         ;put a 0 as input flag
         HEX   2C         ;'BIT XXXX' 3-byte fall through
DSPMEM   LDA   #"= ;store and use as display flag
         STA   DFLAG
         LDX   mCOUNT     ;mCOUNT=# of entries*2+1
         BEQ   DM50       ;no entries/no display
         DEX
         LDA   #9         ;10*8 across for printer
         STA   INDEX      ;makes printer 80 column before C/R
DM10     LDA   MEMAREA,X  ;stored low/high
         STA   DMXX+2     ;for contents display
         JSR   PRBYTE
         DEX
         LDA   MEMAREA,X
         STA   DMXX+1
         JSR   PRBYTE
         LDA   DFLAG      ;0=address only
         BEQ   DM20       ;input req. (do not disp contents)
         JSR   COUT       ;print flag ('=')
         JSR   ZRESTORE   ;pull in proper 0-page
DMXX     LDA   $FFFF      ;read memory contents (avoid
         PHA              ;  0-page conflict)
         JSR   ZSAVE      ;give me back my 0-page
         PLA              ;restore memory contents
         JSR   PRBYTE     ;print it
DM20     DEC   INDEX      ;keep up with line len for printer
         BPL   DM30
         JSR   CROUT      ;new line for printer
         LDA   #9         ;new count for line length
         STA   INDEX
         BRA   DM40       ;era BNE
DM30     LDA   #SPACE     ;separate entries w/space
         JSR   COUT
DM40     DEX              ;next entry
         BPL   DM10
         JSR   CROUT      ;done
         LDA   DFLAG      ;input required?
         BNE   DM70       ;no
         LDX   mCOUNT     ;full?
         CPX   #20
         BCS   DM60       ;yes
DM50     JSR   GETDIG     ;get address, reuse DFLAG
         LDX   mCOUNT
         LDA   DFLAG      ;any entry?
         BEQ   DM60       ;no
         LDA   A1         ;put new address in memory
         STA   MEMAREA,X
         LDA   A1+1
         INX
         STA   MEMAREA,X
         INX
         STX   mCOUNT
DM60     LDA   pFLAG      ;restore output device
         AND   #1
         JSR   DFLTOUT
         JMP   STEPLOOP   ;redo current line
DM70     LDA   pFLAG      ;restore output device
         AND   #1
         JMP   DFLTOUT    ;& return to tracing stream

* Get 16-bit digit

GETDIG   STZ   A1         ;clear workspace (era LDA #0, STA A1)
         STZ   A1+1       ;era STA A1+1
         STZ   DFLAG      ;set only on a valid entry (era STA DFLAG)
GD10     LDA   #23        ;position cursor
         STA   CV
         LDA   #17
         STA   CH
         JSR   VTAB
         JSR   SETINV     ;for emphasis
         LDA   A1+1       ;print current value
         JSR   PRBYTE     ;to scrn only (due to calling rout)
         LDA   A1
         JSR   PRBYTE
         DEC   CH         ;put cursor on image
         JSR   SETNORM
         JSR   RDKEY      ;input
         EOR   #"0 ;hex digit? (see R40 above)
         CMP   #$0A
         BCC   GD20
         ADC   #$88
         CMP   #$FA
         BCC   GD40       ;no
GD20     INC   DFLAG      ;set for valid entry (if <> 256!)
         LDX   #3
         ASL              ;shift to high nibble
         ASL
         ASL
         ASL
GD30     ASL
         ROL   A1
         ROL   A1+1       ;move carry into storage
         DEX
         BPL   GD30
         BMI   GD10       ;more digits
GD40     RTS

* Check current PCNT against breakpoints

BRKCHK   LDX   bCOUNT     ;any to check?
         BEQ   BC30       ;no
         DEX
BC10     LDA   BRKAREA,X  ;stored low/high
         DEX
         CMP   PCNT+1     ;current location
         BNE   BC20       ;no match
         LDA   BRKAREA,X
         CMP   PCNT
         BEQ   BC40       ;match!
BC20     DEX              ;keep looking
         BPL   BC10
BC30     CLC              ;no match
         RTS
BC40     LDA   #$87       ;bell
         JSR   COUT
         SEC
         RTS

* Zero-page movers: I only use $55 and below
* (Also DOS I/O storage so I/O stuff can be traced)

ZRESTORE LDY   #$55       ;save local, restore source
ZR1      LDA   0,Y
         STA   MYZ,Y
         DEY
         BPL   ZR1
         LDY   #3         ;same for DOS memory
ZR2      LDA   DOSINOUT,Y
         STA   MYDOS,Y
         DEY
         BPL   ZR2
         LDY   #$55
ZR3      LDA   PRGZ,Y
         STA   0,Y
         DEY
         BPL   ZR3
         LDY   #3
ZR4      LDA   PRGDOS,Y
         STA   DOSINOUT,Y
         DEY
         BPL   ZR4
         RTS

ZSAVE    JSR   ZSAVE0     ;save source, restore local
         LDY   #$55
ZS3      LDA   MYZ,Y
         STA   0,Y
         DEY
         BPL   ZS3
         LDY   #3
ZS4      LDA   MYDOS,Y
         STA   DOSINOUT,Y
         DEY
         BPL   ZS4
         RTS

ZSAVE0   LDY   #$55       ;save source
ZS1      LDA   0,Y
         STA   PRGZ,Y
         DEY
         BNE   ZS1
         LDY   #3
ZS2      LDA   DOSINOUT,Y
         STA   PRGDOS,Y
         DEY
         BPL   ZS2
         RTS

* Program counter and opcode reader

PRGGET   LDA   $FFFF,X    ;avoid 0 page conflict
         RTS

PCNT     =     PRGGET+1   ;simulated program counter

* Vede se e' una istruzione di branch, se si ritorna con $04
* nell'accumulatore e il flag Z settato

CHKBRC   LDY   LENGTH     ;get length of instruction
         CMP   #$80       ;$80 = BRA
         BEQ   CHKBRC10   ;  altri branch sono nella forma XXX10000
         AND   #%00011111 ;is it a relative branch opcode?
         EOR   #%00010100
         BRA   CHKBRC20
CHKBRC10 LDA   #%00000100
CHKBRC20 CMP   #%00000100 ;if equal, branch--have made
         RTS
