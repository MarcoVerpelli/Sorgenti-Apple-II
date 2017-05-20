******************************
*                            *
* DISKOVERER                 *
* by Bob Gardner             *
* Copyright 1986 by          *
* MicroSPARC. Inc.           *
* Concord, MA  01742         *
*                            *
******************************
*                            *
*       Assembled with       *
*                            *
*         BIG MAC.LC         *
*                            *
******************************
*
*
*   IOB table locations
*
SLOTPOS  =     1
BUFFPOS  =     8
BYTCTPOS =     11
ERRORPOS =     13
IOBPSN   =     15
*
*   Zero page equates
*
IOBPTR   =     $6
TEMP     =     $8
CH       =     $24
BASL     =     $28
LENGTH   =     $2F
MODE     =     $31
PCL      =     $3A
PCH      =     $3B
A2L      =     $3E
*
BUFF     =     $200
*
*   DOS entry points
*
DOSWRM   =     $3D0
RWTS     =     $3D9
GIOB     =     $3E3
*
*   Keyboard location and soft switches
*
KBD      =     $C000
ALTCHOFF =     $C00E
KBDSTRB  =     $C010
*
*   Monitor equates
*
INSTDSP  =     $F8D0
PRBL2    =     $F94A
SETTXT   =     $FB39
TABV     =     $FB5B
SIGBYTE  =     $FBB3
BASCALC  =     $FBC1
BELL3    =     $FBE6
BS       =     $FC10
CLREOP   =     $FC42
HOME     =     $FC58
CLREOL   =     $FC9C
RDKEY    =     $FD0C
CROUT    =     $FD8E
PRBYTE   =     $FDDA
PRHEX    =     $FDE3
COUT     =     $FDED
SETINV   =     $FE80
SETNORM  =     $FE84
SETKBD   =     $FE89
SETVID   =     $FE93
OUTPORT  =     $FE95
BELL     =     $FF3A
GETNUM   =     $FFA7
ZMODE    =     $FFC7
*
         ORG   $7000
*
         LDA   #06        ;Default slot
         STA   CURRSLOT   ;Store it
         ASL              ;Convert to $N0
         ASL
         ASL
         ASL
         STA   SLOTX16    ;And store it
         LDA   #1         ;Default drive
         STA   CURRDRIV
         LDA   #00        ;Default track
         STA   CURRTRAK
         LDA   #00        ;Default sector
         STA   CURRSECT
         LDA   #00
         STA   SAVPOS
         STA   RWTSCMD
         LDA   #00
         STA   HELPFLAG
*
         LDA   #00        ;Set up negative ASCII flag
         STA   APFLAG
         LDA   #$80       ;Set up filter flag
         STA   FILTFLAG
         LDA   #$FF       ;Misc. flags
         STA   DISTRAK
         STA   DISSECT
         STA   SAVTRAK
         STA   SAVSECT
         STA   ZEROFLAG
         LDA   #$FF       ;Printer slot default
         STA   PRSLOT
*
         JSR   BUFFCLR    ;Zero out buffer first
*
         JSR   ZEROCRSR   ;Zero cursor location
*
START    LDA   SIGBYTE    ;Location $FBB3
         CMP   #06        ;Is this a //e?
         BNE   NOTTWOE    ;No
         LDA   #$91       ;Control Q
         JSR   COUT       ;Turn off 80 columns if on
         LDA   #$80       ;Turn on lower case
         STA   ALTCHOFF   ;Turn off alternate char set
         HEX   2C         ;Trick to skip nex two bytes
NOTTWOE  LDA   #$00       ;Turn off lower case flag
         STA   LCASFLAG
         JSR   SETTXT     ;Warm enty
         JSR   SETKBD     ;Disconnect DOS
         JSR   SETVID     ;In and out
         BIT   HELPFLAG   ;Have we been here before?
         BMI   NOHELP     ;Yes
         JSR   HELP       ;Display help screen
         LDA   #$80
         STA   HELPFLAG
NOHELP   JSR   DSPLBUFF   ;Print buffer to screen
INPUT    JSR   DSPLSTAT   ;Current statistics
         JSR   ISCURR     ;Do buffer and T/S match
         JSR   PROMPT
         JSR   RDKEY      ;Get a command
         STA   CURRCMD    ;Save it
         JSR   DOCMD      ;Go do it
         JMP   INPUT      ;Back for another one
*
* Subroutine to find command and execute it
*
DOCMD    LDX   #$FF       ;Initialize index
AGAIN    INX
         LDA   CMDTBL,X   ;Get next character
         BEQ   NOTFOUND   ;Must be end of table
         CMP   CURRCMD    ;Does it match?
         BNE   AGAIN      ;No
         TXA              ;Must be a match
         ASL              ;So compute index
         TAX              ;Into address table
         LDA   ADDRTBL+1,X ;Get address
         PHA              ;Push it on the stack
         LDA   ADDRTBL,X
         PHA
         RTS              ;And go to it
NOTFOUND JMP   BELL       ;Not a valid command
*
* Subroutine to display buffer contenets to screen
*
DSPLBUFF LDA   #$00       ;Initialize registers
         TAY              ;Y is position in buffer
         STA   CH         ;Start at column 1
         JSR   TABV       ;And row 1
LOOP1    LDX   #$0C       ;# of bytes per line
         TYA              ;Save Y for ASCII loop
         PHA
         JSR   PRBYTE     ;Print line number
         LDA   #":"       ;And colon
         JSR   COUT
LOOP     LDA   DISBUFF,Y  ;Get each data byte
         JSR   PRBYTE     ;And print it
         INY
         BEQ   FINISH     ;Whole buffer done
         DEX              ;Position counter
         BNE   LOOP       ;Not ad end of line
         LDA   #" " ;Get a space
         JSR   COUT       ;And print it
FINISH   PLA              ;Restore buffer position
         TAY              ;And put back into Y
         CMP   #$FC       ;Is this the last row?
         BNE   NOTNOW     ;Not yet
         LDX   #17        ;Number of blanks
         JSR   PRBL2      ;And print them
NOTNOW   LDX   #$0C       ;Number of bytes to print
LOOP2    LDA   DISBUFF,Y  ;Get each byte
         JSR   ASCPRINT   ;And print ASCII
         INY
         BEQ   END        ;End of buffer
         DEX
         BNE   LOOP2      ;Still more bytes?
         BEQ   LOOP1      ;Get back for next row
END      JSR   CLREOL     ;Clear end of last line
         JMP   PRNTCRSR   ;And print cursor
*
* Position cursor and put prompt on screen
*
PROMPT   LDA   #00        ;Start at column 1
         STA   CH
         LDA   #22        ;And row 23
         JSR   TABV
         JSR   MSGOUT     ;And print prompt
         ASC   "Command: "
         HEX   00
         JMP   CLREOL     ;Now clear rest of line
*
* Prints current statistics on screen line 24
*
DSPLSTAT LDA   #00        ;Position to column 1
         STA   CH
         LDA   #23        ;And bottom line
         JSR   TABV
         JSR   MSGOUT     ;Print titles
         ASC   "S=  D=  Tr=$   Se=$    F=    L=    +"
         HEX   00
         LDX   #3         ;Number of pieces of data
STAT1    LDA   POSTBL,X   ;Get position
         STA   CH         ;And go there
         LDA   CURRTBL,X  ;Get data
         CPX   #2         ;If less then 2 then decimal data
         BLT   STAT2
         JSR   PRBYTE     ;Print hex byte
         DEX
         BNE   STAT1      ;If not done
STAT2    ORA   #$B0       ;Convert to ASCII
         JSR   COUT       ;And print it
         DEX
         BPL   STAT1      ;Until done
         LDA   #25        ;Position of first flag
         STA   CH
         LDA   FILTFLAG   ;Get status
         JSR   PRNTFLAG   ;And print it
         LDA   #31        ;Position of second flag
         STA   CH
         LDA   LCASFLAG   ;Get status
         JSR   PRNTFLAG   ;And print
         LDA   #36        ;Location of position byte
         STA   CH
         LDA   NEWBFPOS   ;Get position
         JMP   PRBYTE     ;And print it
PRNTFLAG BMI   ON         ;If flag is on
         JSR   MSGOUT     ;Print off
         INV   "OFF"
         HEX   00
         RTS
ON       JSR   MSGOUT     ;Print on
         ASC   "ON "
         HEX   00
         RTS              ;And done
*
*****************************************
* This is where individual commands start
*****************************************
*
* First command just displays current buffer
*
FIXSCRN  JMP   DSPLBUFF   ;Like a null entry
*
* Reads current track and sector and displays buffer
*
READ     LDA   #1         ;Command to read
         STA   RWTSCMD
         JSR   CALLRWTS   ;Read sector
         JSR   ZEROCRSR   ;Put cursor on first byte
         LDA   CURRTRAK   ;And update track
         STA   DISTRAK    ;And sector display
         LDA   CURRSECT
         STA   DISSECT
         JMP   DSPLBUFF   ;Print the buffer
*
* Leaves program and sets up re-entry vector
*
QUIT     JSR   HOME
         PLA              ;Get rid of return address
         PLA
         JSR   MSGOUT     ;Print re-entry message
         ASC   "To re-enter the Diskoverer - CALL 6"
         HEX   8D8D
         HEX   00
         LDA   #$4C       ;Set up re-entry vector
         STA   IOBPTR
         LDA   #<START    ;Warm start address
         STA   IOBPTR+1
         LDA   #>START
         STA   IOBPTR+2
         JMP   DOSWRM     ;Re-start DOS
*
* Reads VTOC sector and displays
*
VTOC     LDA   #$11       ;VTOC track
         STA   CURRTRAK
         LDA   #00        ;VTOC sector
         STA   CURRSECT
         JSR   DSPLSTAT   ;Print stats
         JMP   READ       ;And read it
*
* Reads fisrt catalog sector and displays it
*
CAT      LDA   #$11       ;Catalog track
         STA   CURRTRAK
         LDA   #$0F       ;First catalog sector
         STA   CURRSECT
         JSR   DSPLSTAT   ;Print stats
         JMP   READ       ;And read it
*
* Increment current sector
*
INCSECT  INC   CURRSECT   ;Bump sector
         LDA   CURRSECT
         CMP   #$10       ;See if we wrapped around
         BLT   INCSECT1   ;Not yet
         LDA   #00        ;Yes - so put a zero
         STA   CURRSECT   ;In the sector
         INC   CURRTRAK   ;And bump track
         LDA   CURRTRAK
         CMP   #$23       ;Have we wrapped track?
         BLT   INCSECT1   ;Not yet
         LDA   #00        ;Yes - so put zero
         STA   CURRTRAK   ;Here too
INCSECT1 RTS              ;And out
*
* Decrement current sector
*
DECSECT  DEC   CURRSECT   ;Decrement sector
         BPL   DECSECT1   ;Will go to $FF when it wraps
         LDA   #$0F       ;Start again
         STA   CURRSECT
         DEC   CURRTRAK   ;Decrement track
         BPL   DECSECT1   ;Also will go to $FF
         LDA   #$22       ;Start here again too
         STA   CURRTRAK
DECSECT1 RTS              ;And out
*
* Enter a new track
*
TRACK    JSR   CMDSETUP   ;Position cursor
         JSR   MSGOUT     ;Print prompt
         ASC   "Enter Track: $"
         HEX   00
         JSR   HEXIN      ;Go get a hex byte
         BNE   TRACK2     ;Must have cancelled input
         LDA   A2L        ;Get the input
         CMP   #$23       ;See if it's valid
         BGE   TRACK1     ;No
         STA   CURRTRAK   ;Good track - so store it
TRACK2   RTS              ;And out
TRACK1   JMP   BELL       ;Signals bad input
*
* Enter a new sector
*
SECTOR   JSR   CMDSETUP   ;Same as above
         JSR   MSGOUT
         ASC   "Enter Sector: $"
         HEX   00
         JSR   HEXIN
         BNE   SECTOR2
         LDA   A2L
         CMP   #$10       ;Only 16 sectors
         BGE   SECTOR1
         STA   CURRSECT
SECTOR2  RTS
SECTOR1  JMP   BELL
*
* Toggle slot
*
SLOT     INC   CURRSLOT   ;Bump slot
         LDA   CURRSLOT   ;Get it
         CMP   #08        ;See if we're too far
         BLT   SLOT1      ;Still okay
         LDA   #03        ;Back to the beginning
         STA   CURRSLOT   ;Save new slot
SLOT1    ASL              ;Convert to $N0
         ASL              ;Because DOS needs it that way
         ASL
         ASL
         STA   SLOTX16    ;Save it
         RTS              ;And return
*
* Toggle drive
*
DRIVE    LDA   CURRDRIV   ;Get current drive
         CMP   #1         ;Is it drive 1?
         BEQ   DRIVE1     ;Yes
         LDA   #1         ;No - so make it a 1
         STA   CURRDRIV   ;Save it
         BNE   DRIVE2
DRIVE1   INC   CURRDRIV   ;Bump drive
DRIVE2   RTS              ;Return
*
* Toggle display filter flag
*
FILTER   LDA   FILTFLAG   ;Get current status
         EOR   #$80       ;Toggle it
         STA   FILTFLAG   ;Store it
         JMP   DSPLBUFF   ;And display on the way out
*
* Toggle Applesoft filter flag
*
APFILTER LDA   APFLAG     ;Get current status
         EOR   #$80       ;Toggle it
         STA   APFLAG     ;Store it
         JMP   DSPLBUFF   ;And display on the way out
*
* Toggle lower case display
*
LCASE    LDA   LCASFLAG   ;Get current status
         EOR   #$80       ;Toggle it
         STA   LCASFLAG   ;Save it
         JMP   DSPLBUFF   ;And display on the way out
*
* Writes a sector to disk
*
WRITE    JSR   CMDSETUP   ;Position cursor
         JSR   MSGOUT     ;Print verification msg
         INV   "WRITE BUFFER TO TR=$   SE=$     (Y/N)"
         HEX   00
         JSR   SETINV
         LDA   #20        ;Cursor position
         STA   CH
         LDA   CURRTRAK   ;Get track
         JSR   PRBYTE     ;And print it
         LDA   #27
         STA   CH
         LDA   CURRSECT   ;Get sector
         JSR   PRBYTE     ;And print it
         JSR   SETNORM
         LDA   #38
         STA   CH
         JSR   RDKEY      ;Get a keystroke
         CMP   #"Y"       ;Was it a 'Y' ?
         BNE   WRITE1     ;No
         LDA   $7F7       ;Is this a match?
         CMP   #"="       ;With the display
         BEQ   WRITE2     ;Yes so write
         JSR   CMDSETUP
         JSR   CLREOP
         JSR   MSGOUT     ;Make sure one more time
         FLS   "** WARNING SECTOR/BUFFER MISMATCH **"
         HEX   8D
         FLS   " DO YOU WANT TO WRITE ANYWAY (Y/N) "
         HEX   00
         JSR   RDKEY      ;Get another key
         CMP   #"Y"       ;Yes this time too?
         BNE   WRITE1     ;Not this time
WRITE2   LDA   #2         ;Command to write
         STA   RWTSCMD    ;Set it up
         JSR   CALLRWTS   ;And write
         JSR   ZEROCRSR   ;Put cursor at the top
         JMP   DSPLBUFF   ;And show sector
WRITE1   RTS
*
* Zeroes out either or both buffer
*
ZERO     JSR   CMDSETUP
         JSR   MSGOUT     ;Print the prompt
         ASC   "D)isplay buffer, S)ave buffer, or B)oth"
         HEX   00
         JSR   RDKEY      ;Get a keystroke
         CMP   #"B"       ;Clear both?
         BNE   ZERO1      ;No
         LDA   #$FF       ;Show no valid data in buffer
         STA   SAVTRAK
         LDA   #$C0       ;Flag to clear both buffers
         STA   ZEROFLAG
ZERO5    JSR   ZEROCRSR   ;Put cursor back to beginning
ZERO4    JSR   BUFFCLR    ;Clear the buffer(s)
         JSR   DSPLBUFF   ;And display them
ZERO3    RTS
ZERO1    CMP   #"S"       ;Just the save buffer?
         BNE   ZERO2      ;No
         LDA   #$FF       ;No valid data in buffer
         STA   SAVTRAK
         LDA   #$40       ;Flag to clear save buffer
         STA   ZEROFLAG
         BNE   ZERO4      ;And do it
ZERO2    CMP   #"D"       ;Was it the display buffer?
         BNE   ZERO3      ;No vlid key so leave
         LDA   #$80       ;Flag fo the display buffer
         STA   ZEROFLAG
         BNE   ZERO5      ;And do it
*
* Move cursor one space to the right
*
RIGHT    INC   NEWBFPOS   ;Bump buffer position
         BNE   RIGHT1     ;Make sure we're not at the end
         DEC   NEWBFPOS   ;We are so stay there
         BNE   RIGHT2     ;And leave
RIGHT1   INC   NEWLNPOS   ;Bump position in line
         LDA   NEWLNPOS
         CMP   #$0C       ;Time to wrap around?
         BLT   RIGHT2     ;Not yet
         LDA   #00        ;Beginning of next line
         STA   NEWLNPOS
         INC   NEWROW     ;Now bump the row
RIGHT2   JSR   ERASCRSR   ;Show new position
         JMP   PRNTCRSR
*
* Move cursor one space to the left
*
LEFT     LDA   #00
         CMP   NEWBFPOS   ;Are we already at the beginning
         BNE   LEFT1      ;No
         RTS              ;Yes so do nothing
LEFT1    DEC   NEWBFPOS   ;Decrement buffer position
         DEC   NEWLNPOS   ;Now drop the line position
         BPL   LEFT2      ;Were we at the left end?
         LDA   #$0B       ;Yes so go to end of line
         STA   NEWLNPOS
         DEC   NEWROW     ;And drop back one row
LEFT2    JSR   ERASCRSR   ;And show new position
         JMP   PRNTCRSR
*
* Move cursor up one space
*
UP       LDA   #00
         CMP   NEWROW     ;Are we at the top?
         BNE   UP1        ;Not yet
         CMP   NEWLNPOS   ;If we are
         BEQ   UP2        ;Are we at the beginning?
         JMP   BEGIN      ;Put us there
UP2      RTS
UP1      DEC   NEWROW     ;Decrement row
         SEC
         LDA   NEWBFPOS   ;Now subtract 12
         SBC   #$0C       ;To get buffer position
         STA   NEWBFPOS
         JSR   ERASCRSR   ;And show new position
         JMP   PRNTCRSR
*
* Move cursor down one space
*
DOWN     LDA   NEWBFPOS   ;Get current position
         CMP   #$FF       ;Are we at the end already?
         BNE   DOWN1      ;Not yet
         RTS              ;We were there
DOWN1    CMP   #$F4       ;Are we on the last line?
         BLT   DOWN2      ;No
         JMP   ENDING     ;We were so jump to the end
DOWN2    CLC
         ADC   #12        ;Add 12 to current position
         STA   NEWBFPOS
         INC   NEWROW     ;Now bunp row
         JSR   ERASCRSR   ;And display new position
         JMP   PRNTCRSR
*
* Move cursor to beginning of buffer
*
BEGIN    JSR   ZEROCRSR   ;Zero out cursor locations
         JSR   ERASCRSR   ;And display new cursor
         JMP   PRNTCRSR
*
* Move cursor to end of buffer
*
ENDING   LDA   #$FF       ;Set up variables
         STA   NEWBFPOS   ;To point at end
         LDA   #3         ;Of buffer
         STA   NEWLNPOS
         LDA   #21
         STA   NEWROW
         JSR   ERASCRSR   ;And display new cursor
         JMP   PRNTCRSR
*
* Save current buffer to save buffer
*
NEW      LDX   #00
NEW1     LDA   DISBUFF,X  ;Get a byte
         STA   SAVBUFF,X  ;Move it
         LDY   #01        ;Set up for click
         TYA
         JSR   BELL3      ;Do the click
         INX              ;Next byte
         BNE   NEW1       ;If not at the end of buffer
         LDA   DISTRAK    ;Now transfer
         STA   SAVTRAK    ;Display data
         LDA   DISSECT    ;To save data table
         STA   SAVSECT
         LDA   NEWBFPOS
         STA   SAVPOS
         RTS              ;And get out
*
* Restore display buffer drom save buffer
*
OLD      LDA   SAVTRAK    ;Get old track
         BPL   OLD2       ;Only if it's a valid track
         JSR   BELL       ;Ring the bell
         JSR   CMDSETUP
         JSR   MSGOUT     ;And let them know what's wrong
         ASC   "No Sector in save buffer..."
         HEX   00
         JMP   RDKEY      ;Wait for a key
OLD2     STA   CURRTRAK   ;Move save data to
         STA   DISTRAK    ;Current data and
         LDA   SAVSECT    ;Display data
         STA   CURRSECT
         STA   DISSECT
         LDX   #00        ;Set up counter
OLD1     LDA   SAVBUFF,X  ;Get a byte
         STA   DISBUFF,X  ;Move it
         INX              ;Next byte
         BNE   OLD1       ;If not done yet
         LDA   SAVPOS     ;Find out where cursor was
         STA   A2L
         JSR   FINDCRSR
         JMP   DSPLBUFF   ;Now show it
*
* Enter new ASCII data
*
ASCII    JSR   CMDSETUP
         JSR   MSGOUT     ;Print a prompt
         ASC   "Enter ASCII: "
         HEX   00
         LDA   #00        ;ASCII not hex
         STA   HEXFLAG
         LDA   #25        ;Allow 24 characters
         STA   INPUTLEN
         JSR   INPUTSTR   ;Get the input
         LDX   #00        ;Counter for buffer
ASCII2   LDY   NEWBFPOS   ;Find out where it goes
         LDA   INPBUFF,X  ;Get a character
         BNE   ASCII1     ;Only if we're not at the end
         RTS              ;That's all of them
ASCII1   STA   DISBUFF,Y  ;Stuff it into buffer
         CPY   #$FF       ;Is this the end?
         BNE   ASCII3     ;No so get some more
         JMP   RIGHT      ;Move cursor and exit
ASCII3   JSR   RIGHT      ;Move cursor
         INX
         BNE   ASCII2     ;And go back for more
*
* Move cursor to specified position
*
GOTO     JSR   CMDSETUP
         JSR   MSGOUT     ;Start with a prompt
         ASC   "Go to position: $"
         HEX   00
         JSR   HEXIN      ;Now get hex input
         BNE   GOTO1      ;If no valid input
         LDA   A2L        ;Get the new position
         JSR   FINDCRSR   ;Find it
         JSR   ERASCRSR   ;And print it
         JSR   PRNTCRSR
GOTO1    RTS
*
* Enter new hex data
*
HEX      JSR   CMDSETUP
         JSR   MSGOUT     ;First the prompt
         ASC   "Enter HEX: "
         HEX   00
         LDA   #$80       ;This is hex input
         STA   HEXFLAG
         LDA   #25        ;24 characters
         STA   INPUTLEN
         JSR   INPUTSTR   ;Get the input
         LDX   #00        ;Set up index
HEX3     LDA   INPBUFF,X  ;Get a character
         BNE   HEX1       ;If not the end yet
HEX2     RTS
HEX1     STA   BUFF       ;Stuff it into input buffer
         INX
         LDA   INPBUFF,X  ;Get next character
         BEQ   HEX2       ;Must be odd number
         STA   BUFF+1     ;Stuff it
         INX
         STX   TEMP       ;Save index
         LDY   #00
         STY   BUFF+2     ;Make this the end
         STY   MODE       ;Monitor needs this
         JSR   GETNUM     ;Let the monitor do the work
         LDY   NEWBFPOS   ;Get buffer position
         LDA   A2L        ;Get the byte
         STA   DISBUFF,Y  ;Stuff it into buffer
         CPY   #$FF       ;Was that the last one?
         BNE   HEX4       ;Guess not
         JMP   RIGHT      ;Move right and get out
HEX4     JSR   RIGHT      ;Move right
         LDX   TEMP       ;Restore index
         JMP   HEX3       ;And go back for more
*
* Dumps screen contents to printer
*
PRINT    LDA   #24        ;Print full screen
         STA   PRINTLEN
         STA   PRNTBYTE   ;Flag to erase cursor
PRINT8   LDA   PRSLOT     ;Get current slot
         CMP   #$08       ;Has it been entered yet?
         BLT   PRINT7     ;Yes
         JSR   CMDSETUP
         JSR   MSGOUT
         ASC   "Enter printer slot# (1-7): "
         HEX   00
         JSR   RDKEY
         CMP   #$B1       ;Slot one
         BLT   PRINT2
         CMP   #$B8       ;Slot seven
         BLT   PRINT1
PRINT2   RTS              ;Invalid slot
PRINT1   AND   #$07
         STA   PRSLOT     ;Now save it
PRINT7   PHA
         LDA   PRNTBYTE   ;Erase cursor?
         BMI   PRINT9     ;No
         JSR   ERASCRSR
PRINT9   JSR   CMDSETUP
         JSR   CLREOL     ;Get rid of prompt
         PLA              ;Restore slot
         JSR   OUTPORT    ;Turn on printer
         LDA   #00
         STA   CH
         JSR   TABV
         JSR   MSGOUT     ;Initialization
         HEX   89         ;Control I
         ASC   "80N"
         HEX   00
         HEX   EAEAEAEAEAEAEAEAEAEA
         LDX   #00        ;Initialize line counter
PRINT4   TXA
         PHA
         JSR   BASCALC    ;Calculate line position
         LDX   #20
         JSR   PRBL2      ;Center on printer
         LDY   #00        ;Character count
PRINT3   LDA   (BASL),Y   ;Get a character
         CMP   #$20       ;Check for control
         BGE   PRINT5
         ORA   #$40
PRINT5   CMP   #$FF       ;Check for deleted
         BNE   PRINT6
         LDA   #" " ;Don't print deleted files
PRINT6   JSR   COUT       ;Print character
         INY
         CPY   #40        ;End of line?
         BLT   PRINT3
         JSR   CROUT
         PLA              ;Get line count
         TAX
         INX
         CPX   PRINTLEN   ;End of screen?
         BLT   PRINT4
         JSR   CROUT      ;Skip a few lines
         JSR   CROUT
         JSR   CROUT
         JSR   SETVID     ;Turn off printer
         LDA   PRNTBYTE   ;Do we need to put cursor back?
         BMI   PRINTOUT
         JMP   PRNTCRSR   ;Print cursor
PRINTOUT RTS
*
* Load track from cursor position
*
SETTRAK  LDY   NEWBFPOS   ;Get position
         LDA   DISBUFF,Y  ;Now get byte
         CMP   #$23       ;Is it valid?
         BGE   SETTRAK1   ;No
         STA   CURRTRAK   ;Save it
         JMP   RIGHT
SETTRAK1 JMP   BELL
*
* Load sector from cursor position
*
SETSECT  LDY   NEWBFPOS   ;Just like the track
         LDA   DISBUFF,Y
         CMP   #$10
         BGE   SETSECT1
         STA   CURRSECT
         JMP   RIGHT
SETSECT1 JMP   BELL
*
* Loads track/sector and reads
*
SETREAD  JSR   SETTRAK    ;First get the track
         BCS   SETREAD1   ;Carry set if not valid
         JSR   SETSECT    ;Now the sector
         BCS   SETREAD1
         JSR   NEW        ;Save the buffer
         JMP   READ       ;Now read the new one
SETREAD1 RTS
*
* Reads first sector of a file
*
INDREAD  JSR   SETREAD    ;First get track/sector list
         BCS   IND1       ;If invalid track or sector
         JSR   DOWN       ;First track/sector pair
         JMP   CONT4      ;Go to continue read
IND1     RTS
*
* Locates and reads next sector
*
CONTREAD JSR   OLD        ;Get track/sector list
         LDY   NEWBFPOS
         CPY   #$FF       ;Are we at the end of the buffer?
         BNE   CONT1      ;No so skip ahead
CONT3    LDA   DISBUFF+1  ;Get link track
         BEQ   END1       ;Must not be one
         CMP   #$23       ;It is valid?
         BGE   END2       :No
         STA   CURRTRAK
         LDA   DISBUFF+2  ;Now get link sector
         CMP   #$10
         BGE   END2
         STA   CURRSECT
         JSR   NEW        ;Save current sector
         JSR   READ       ;Read new list
         JSR   DOWN       ;Set up for first pair
CONT4    LDY   NEWBFPOS
CONT1    LDA   DISBUFF,Y  ;Get track
         BNE   CONT2      ;Branch if good
         INY              ;Bump to next pair
         INY
         BEQ   CONT3      ;End of sector
         BNE   CONT1      ;Try again
CONT2    TYA              ;New cursor position
         STA   A2L
         JSR   FINDCRSR   ;Now locate and
         JSR   ERASCRSR   ;Print cursor
         JSR   PRNTCRSR
         LDY   NEWBFPOS   ;Get position back
         JMP   SETREAD    ;And read sector
END1     JMP   CATLINK1   ;Error message
END2     JMP   CATLINK2   ;Error message
*
* Disassemble twenty lines
*
EXAMINE  JSR   HOME
         LDA   #20        ;Number of lines to disassemble
         STA   TEMP
         LDA   #>DISBUFF  ;Now set up
         STA   PCH        ;Program counter
         LDY   NEWBFPOS
         STY   A2L
EXAM2    STY   PCL
         JSR   INSTDSP    ;And do 1 instruction
         LDX   LENGTH     ;How many bytes?
EXAM1    INC   A2L        ;Bump counter
         LDY   A2L        ;Transfer to y
         BEQ   EXAM3      ;End of buffer
         DEX
         BPL   EXAM1      ;If more bytes
         DEC   TEMP       ;Decrement line counter
         LDA   TEMP
         BNE   EXAM2
EXAM3    LDA   A2L        ;New cursor position
         JSR   FINDCRSR
EXAM5    JSR   CMDSETUP
         JSR   CLREOL
         JSR   MSGOUT     ;Print out a prompt
         ASC   "Press a key..."
         HEX   00
         JSR   RDKEY
         CMP   #$90       ;Was it control P?
         BNE   EXAM4
         LDA   #21        ;Lines to print
         STA   PRINTLEN
         LDA   #$80       ;Don't erase cursor
         STA   PRNTBYTE
         JSR   PRINT8     ;Print the screen
         JMP   EXAM5
EXAM4    CMP   #"X"       ;Another 20 lines?
         BEQ   EXAMINE
         JMP   DSPLBUFF   ;No then leave
*
* Reads next link sector
*
CATLINK  LDA   DISBUFF+1  ;Get track link first
         BEQ   CATLINK1   ;0 not a valid trak
         CMP   #$23       ;Make sure it's less then $23 (***MV***)
         BGE   CATLINK2
         STA   CURRTRAK
         LDA   DISBUFF+2  ;New get sector
         CMP   #$10       ;Is it valid?
         BGE   CATLINK2
         STA   CURRSECT
         JMP   READ       ;Now read it
CATLINK1 JSR   BELL       ;Comes here when at end of link
         JSR   CMDSETUP
         JSR   MSGOUT
         ASC   "End of Track/Sector link..."
         HEX   00
         JMP   RDKEY
CATLINK2 JSR   BELL       ;Comes here when invalid T/S
         JSR   CMDSETUP
         JSR   MSGOUT
         ASC   "Invalid Track or Sector..."
         HEX   00
         JMP   RDKEY
*
* Advance cursor to first byte of file entry
*
NXTFILE  LDA   NEWBFPOS   ;Get position in buffer
         LDY   #06
NXTFILE1 CMP   FILETABL,Y ;Are we before this file?
         BLT   NXTFILE2   ;Yes
         DEY
         BPL   NXTFILE1   ;Try next entry
         LDY   #06        ;Or back to the beginning
NXTFILE2 LDA   FILETABL,Y ;Get position
         STA   A2L        ;Save it
         JSR   FINDCRSR   ;And move the cursor
         JSR   ERASCRSR
         JMP   PRNTCRSR
*
* Generate a test screen
*
TEST     LDY   #00        ;Initialize loop
TEST1    TYA
         STA   DISBUFF,Y  ;Store character
         INY              ;Next char
         BNE   TEST1      ;If not done
         DEY              ;$FF
         STY   DISTRAK    ;Not a valid track
         JSR   ISCURR     ;Update flag
         JMP   DSPLBUFF   ;Now display it
*
* Reads and displays next track/sector
*
NEXT     JSR   INCSECT    ;Bump sector
         JMP   READ       ;And read
*
* Reads and displays previous track/sector
*
PREVIOUS JSR   DECSECT    ;Decrement sector
         JMP   READ       ;And read
*
* Set all or part of buffer to specific byte
*
ZEROPART JSR   CMDSETUP
         JSR   MSGOUT     ;Print a prompt
         ASC   "Enter byte to set: $"
         HEX   00
         JSR   HEXIN      ;Get a hex byte
         BNE   ZP2        ;If null entry
         LDA   A2L        ;Get byte
         LDY   NEWBFPOS   ;Get current position in buffer
ZP1      STA   DISBUFF,Y  ;Store byte
         INY              ;Next position
         BNE   ZP1        ;If not at end
         JSR   DSPLBUFF   ;Display buffer
ZP2      RTS
*
* Calculate and display disk free space
*
FREESPAC JSR   NEW        ;Save current sector
         JSR   VTOC       ;Read in VTOC
         BCS   FREE5      ;If error
         LDA   #00        ;Zero out temp storage
         STA   TEMP
         STA   TEMP+1
         LDY   #$C3       ;End of T/S map in buffer
FREE3    LDA   DISBUFF,Y  ;Get a byte from buffer
         LDX   #07        ;Number of times to shift
FREE2    ASL              ;Get bit into carry
         BCC   FREE1      ;If used
         PHA              ;Save byte
         SED              ;Use decimal mode
         LDA   TEMP+1     ;Get current count
         CLC
         ADC   #01        ;Add one
         STA   TEMP+1
         LDA   TEMP       ;In case of a carry
         ADC   #00
         STA   TEMP
         PLA              ;Get byte back
FREE1    CLD
         DEX              ;Another shift
         BPL   FREE2      ;If not done
         DEY              ;Another Y
         CPY   #$38       ;At end yet?
         BGE   FREE3      ;Must not be
         JSR   CMDSETUP
         LDA   TEMP       ;Get high byte
         JSR   PRHEX      ;Print low nibble
         LDA   TEMP+1     ;Get low byte
         JSR   PRBYTE     ;Print it
         JSR   MSGOUT
         ASC   " sectors free..."
         HEX   00
         JMP   RDKEY      ;Wait for a key
FREE5    RTS
*
*******************************************************
* The following are general purpose subroutines used by
* Many of the individual commands in the main program
*******************************************************
*
* Prints an ASCII character with all flags in effect
*
ASCPRINT CMP   #$A0       ;Normal ASCII?
         BGE   CASECHK    ;Yes
         BIT   FILTFLAG   ;Is filter flag on?
         BPL   NOFILTER
         BIT   APFLAG     ;Is negative flag on?
         BPL   ASC4
         ORA   #$80       ;Turn on high bit
         CMP   #$A0       ;Is it a control char?
         BGE   CASECHK    ;No
ASC4     LDA   #"."       ;Print a period
         BNE   ASCOUT
NOFILTER CMP   #$80       ;Is it a control?
         BLT   ASC1       ;No
         AND   #$1F       ;Convert to flashing
         ORA   #$40
         BNE   ASCOUT
ASC1     CMP   #$40       ;Already inverse?
         BLT   ASC2       ;Yes
         AND   #$1F       ;Convert
         JMP   ASCOUT
ASC2     CMP   #$20       ;Is it a control?
         BGE   ASCOUT     ;No
         ORA   #$40
         BNE   ASCOUT
CASECHK  BIT   LCASFLAG   ;Now check case flag
         BMI   ASCOUT     ;If on
         CMP   #$A0       ;Is it control or positive?
         BLT   ASC3       ;Yes
         CMP   #$E0       ;Is it lower case?
         BLT   ASCOUT     ;No
         AND   #$DF       ;Convert to upper
         BNE   ASCOUT
ASC3     CMP   #$20       ;Is it a control?
         BLT   ASCOUT     ;Yes
         AND   #$1F       ;Convert
ASCOUT   JMP   COUT       ;Finally print it
*
* Position cursor to command line
*
CMDSETUP LDA   #$00       ;Beginning on line
         STA   CH
         LDA   #22        ;Screen line
         JMP   TABV       ;Do the positioning
*
* Input a hex byte
*
HEXIN    LDA   #03        ;Set up for 2 characters
         STA   INPUTLEN
         LDA   #$80       ;Set up for hex input
         STA   HEXFLAG
         JSR   INPUTSTR   ;Now get input
         LDY   #02        ;Index to buffer
HEXIN1   LDA   INPBUFF,Y  ;Move string into
         BNE   HEXIN2     ;Input buffer
         LDA   #$8D       ;Add carriage return
HEXIN2   STA   BUFF,Y
         DEY
         BPL   HEXIN1
         JSR   ZMODE      ;Required by monitor
         JSR   GETNUM     ;Use monitor to parse
         LDA   BUFF
         CMP   #$8D       ;Null input?
         BNE   HEXIN3
         PLA              ;If null pop return
         PLA
HEXIN3   LDA   #00        ;Flag for input
         RTS
*
* RTWTS caller to read in a track and sector
*
CALLRWTS JSR   GIOB       ;Find IOB
         STY   IOBPTR     ;And save location
         STA   IOBPTR+1
         LDY   #SLOTPOS   ;Index to IOB
         LDA   SLOTX16    ;Store slot
         STA   (IOBPTR),Y
         INY
         LDA   CURRDRIV   ;Store drive
         STA   (IOBPTR),Y
         INY
         LDA   #00        ;Default volume
         STA   (IOBPTR),Y
         INY
         LDA   CURRTRAK   ;Track to read
         STA   (IOBPTR),Y
         INY
         LDA   CURRSECT   ;Sector to read
         STA   (IOBPTR),Y
         LDY   #BUFFPOS
         LDA   #<DISBUFF  ;Low byte of buffer
         STA   (IOBPTR),Y
         INY
         LDA   #>DISBUFF  ;High byte of buffer
         STA   (IOBPTR),Y
         LDY   #BYTCTPOS
         LDA   #00        ;Byte count
         STA   (IOBPTR),Y
         INY
         LDA   RWTSCMD    ;Command code
         STA   (IOBPTR),Y
         LDY   #IOBPSN
         LDA   SLOTX16    ;Slot
         STA   (IOBPTR),Y
         INY
         LDA   CURRDRIV   ;Drive
         STA   (IOBPTR),Y
         LDY   IOBPTR
         LDA   IOBPTR+1
         JSR   RWTS       ;Call the RWTS subroutine
         LDA   #00        ;Fix for status register
         STA   $48
         BCS   ERROR      ;RWTS sets carry for error
         RTS              ;Good exit
ERROR    JSR   CMDSETUP
         JSR   CLREOL
         JSR   MSGOUT     ;Print error message
         ASC   "** RWTS error ** "
         HEX   00
         LDY   #ERRORPOS
         LDA   (IOBPTR),Y ;Get error code
         CMP   #$10       ;Write protect error
         BNE   ERROR1
         JSR   MSGOUT
         ASC   "Write Protected..."
         HEX   00
         JMP   ERROROUT
ERROR1   CMP   #$40       ;Drive error
         BNE   ERROR2
         JSR   MSGOUT
         ASC   "Drive Error..."
         HEX   00
         JMP   ERROROUT
ERROR2   PHA              ;Save code
         JSR   MSGOUT     ;Print message
         ASC   "Code# $"
         HEX   00
         PLA              ;Get code back
         JSR   PRBYTE     ;And print it
ERROROUT PLA              ;Pop return
         PLA
         JSR   BELL
         JSR   RDKEY      ;Wait for a key
         SEC              ;Just like DOS
         RTS
*
* Set up location for new cursor position
*
FINDCRSR CMP   NEWBFPOS   ;Accumulator has buffer position
         BNE   FIND1      ;If no match
         RTS
FIND1    INC   NEWBFPOS   ;Bunp buffer position
         BNE   FIND2      ;If not at beginning
         LDA   #00        ;Set all locations to zero
         STA   NEWLNPOS
         STA   NEWROW
         BEQ   FIND3      ;See if we are at new position
FIND2    INC   NEWLNPOS   ;Bump line
         LDA   NEWLNPOS
         CMP   #$0C       ;At end?
         BLT   FIND3      ;No
         LDA   #00        ;Back to zero
         STA   NEWLNPOS
         INC   NEWROW     ;Bump row
FIND3    LDA   NEWBFPOS   ;Get new position
         CMP   A2L        ;Are we there yet?
         BNE   FIND1      ;No
         RTS
*
* Erase old cursor
*
ERASCRSR LDA   OLDROW     ;Get row
         JSR   TABV       ;Go to it
         LDA   OLDLNPOS   ;Get line position
         ASL              ;Double it
         CLC
         ADC   #3         ;Add offset
         STA   CH         ;Position cursor
         LDY   OLDBFPOS
         LDA   DISBUFF,Y  ;Get byte
         PHA              ;Save it
         JSR   PRBYTE     ;And print it
         LDA   #28
         CLC
         ADC   OLDLNPOS   ;Calculate ASCII position
         STA   CH
         PLA              ;Get byte back
         JMP   ASCPRINT   ;And print it
*
* Print cursor to screen
*
PRNTCRSR LDA   NEWROW     ;Get row position
         JSR   TABV       ;Go to it
         LDA   NEWLNPOS   ;Get line position
         ASL              ;Double it
         CLC
         ADC   #3         ;And offset
         TAY
         JSR   INVERT     ;Print character in inverse
         INY
         JSR   INVERT     ;Now the next one
         LDA   #28
         CLC
         ADC   NEWLNPOS   ;Calculate ASCII offset
         TAY
         JSR   INVERT     ;Print in inverse
         LDY   #2         ;Now move new table to old table
PRNTCSR1 LDA   NEWBFTBL,Y
         STA   OLDBFTBL,Y
         DEY
         BPL   PRNTCSR1
         RTS
*
* Gets character from screen and prints it in inverse
*
INVERT   LDA   (BASL),Y   ;Get character
         CMP   #$E0       ;Lower case?
         BLT   INVERT1    ;No
         AND   #$DF       ;Convert to upper
INVERT1  AND   #$3F       ;Convert to inverse
         STA   (BASL),Y   ;Put character back
         RTS
*
* Zero out cursor position table
*
ZEROCRSR LDA   #00
         LDX   #2
ZEROCSR1 STA   NEWBFTBL,X
         DEX
         BPL   ZEROCSR1
         RTS
*
* Zero out buffers depending on flag condition
*
BUFFCLR  LDY   #00        ;Zero registers
         TYA
CLR1     BIT   ZEROFLAG   ;Get status of flags
         BPL   CLR2       ;Don't clear display buffer
         STA   DISBUFF,Y
CLR2     BVC   CLR3       ;Don't clear save buffer
         STA   SAVBUFF,Y
CLR3     INY
         BNE   CLR1       ;If not done yet
         RTS
*
* Update sector/buffer status flag
*
ISCURR   LDA   CURRTRAK   ;Check track first
         CMP   DISTRAK    ;Same?
         BNE   ISCURR1    ;No
         LDA   CURRSECT   ;Check sector
         CMP   DISSECT
         BNE   ISCURR1
         LDA   #"="       ;Must be a match
         BNE   ISCURR2
ISCURR1  LDA   #$2A       ;No match
ISCURR2  STA   $7F7       ;Store on screen
         RTS
*
* Input a hex or ASCII string
*
INPUTSTR LDX   #$FF       ;Initialize flags
         STX   INVFLAG
         INX
         STX   FLSFLAG
         STX   SHFTFLAG
INP1     JSR   FLAGS      ;Now display them
         JSR   RDKEY      ;Get a keystroke
         BIT   HEXFLAG    ;Is this hex input?
         BPL   NOHEX      ;No
         PHA              ;Save the key
         CMP   #$98       ;Is it control X?
         BEQ   GOODHEX
         CMP   #$8D       ;Is it a return?
         BEQ   GOODHEX
         CMP   #$88       ;Is it a backspace?
         BEQ   GOODHEX
         EOR   #$B0       ;Now check for
         CMP   #$0A       ;Valid hex digit
         BLT   GOODHEX    ;Like in the monitor
         ADC   #$88
         CMP   #$FA
         BGE   GOODHEX
         PLA              ;Fix stack
         JSR   BELL
         JMP   INP1       ;Try again
GOODHEX  PLA              ;Restore character
NOHEX    CMP   #$8F       ;Is it control O?
         BNE   INP2
         JSR   RDKEY      ;Get next key
         JMP   INP10      ;And enter directly
INP2     CMP   #$93       ;Is it control S?
         BNE   INP3
         LDA   SHFTFLAG   ;Get shift flag
         EOR   #$80       ;And toggle it
         STA   SHFTFLAG
         JMP   INP1
INP3     CMP   #$8E       ;Is it control N?
         BNE   INP4
         LDY   #$FF
         STY   INVFLAG    ;Condition flags for normal
         INY
         STY   FLSFLAG
         BEQ   INP1
INP4     CMP   #$86       ;Is it control F?
         BNE   INP5
         LDY   #$3F
         STY   INVFLAG    ;Condition flags for flashing
         INY
         STY   FLSFLAG
         BNE   INP1
INP5     CMP   #$89       ;Is it control I?
         BNE   INP6
         LDY   #$3F
         STY   INVFLAG    ;Condition flags for inverse
         LDY   #00
         STY   FLSFLAG
         BEQ   INP1
INP6     CMP   #$88       ;Is it control H?
         BEQ   BACKSPAC   ;Then do a back space
         CMP   #$8D       ;Is it control M?
         BEQ   DONE       ;Then finish up
         CMP   #$98       ;Is it control X?
         BNE   INP7
         PLA              ;Pop the return address
         PLA
         LDA   #$FF       ;Condition accumulator
         RTS              ;And leave
INP7     CMP   #$A0       ;Is it a control character?
         BGE   INP8       ;No
         JSR   BELL
         JMP   INP1       ;Try again
INP8     CMP   #$C0       ;Is it a letter?
         BLT   INP9       ;No
         BIT   SHFTFLAG   ;Check shift flag
         BPL   INP9
         ORA   #$20       ;Make lower case
         BNE   INP10
INP9     AND   INVFLAG    ;Mask with inv and fls flags
         ORA   FLSFLAG
INP10    STA   INPBUFF,X  ;Store character in buffer
         CMP   #$E0       ;Is it lower case?
         BLT   INP11      ;No
         BIT   LCASFLAG   ;Check case flag
         BMI   INP11
         AND   #$DF       ;Convert to upper
INP11    CMP   #$A0       ;Is it control?
         BGE   OUTPUT     ;No
         CMP   #$80       ;Flash or inverse
         BLT   OUTPUT     ;Yes
         AND   #$1F       ;Convert to flashing
         ORA   #$40
OUTPUT   JSR   COUT       ;Finally print it
         INX              ;Buffer position
         CPX   INPUTLEN   ;At the end yet?
         BEQ   INP12      ;Yes
         JMP   INP1       ;Back for another
INP12    JSR   BELL       ;Warn user
BACKSPAC CPX   #$00       ;Fall into backspace
         BNE   INP13      ;If not at beginning
         JMP   INP1       ;Just go back for another hit
INP13    JSR   BS         ;Back up
         LDA   #" " ;Erase character
         JSR   COUT
         JSR   BS         ;Back up again
         DEX              ;Fix counter
         JMP   INP1       ;Another hit
DONE     LDA   #00        ;Mark end of buffer
         STA   INPBUFF,X
         JMP   CLREOL     ;And out
*
* Print input status flags
*
FLAGS    BIT   SHFTFLAG   ;Are we shifted?
         BPL   FLAG1
         LDA   #"L"       ;Lower case
         BNE   FLAG2
FLAG1    LDA   #"U"       ;Upper case
FLAG2    STA   $776       ;Store it in screen
         BIT   INVFLAG    ;Check inverse flag
         BPL   FLAG3
         LDA   #"N"       ;Normal
         BNE   FLAG4
FLAG3    LDA   FLSFLAG
         BNE   FLAG5
         LDA   #$09       ;Inverse
         BNE   FLAG4
FLAG5    LDA   #$46       ;Flashing
FLAG4    STA   $777       ;Store it in screen
         RTS
*
* Print a message to the screen
*
MSGOUT   PLA              ;Get address of message
         STA   TEMP       ;And save it
         PLA
         STA   TEMP+1
         LDY   #0         ;Initialize counter
MSGOUT1  INC   TEMP       ;Bump address
         BNE   SKIPADD    ;If no warparound
         INC   TEMP+1     ;Bump high order
SKIPADD  LDA   (TEMP),Y   ;Get byte
         BEQ   MSGRTS     ;00 marks end of message
         BIT   LCASFLAG   ;Check case flag
         BMI   NOCONVRT
         CMP   #$E0       ;Is it lower case
         BLT   NOCONVRT
         AND   #$DF       ;Convert to upper
NOCONVRT JSR   COUT       ;Print it
         JMP   MSGOUT1    ;Back for another
MSGRTS   LDA   TEMP+1     ;Get return address back
         PHA              ;And put it on the stack
         LDA   TEMP
         PHA
         RTS              ;And out
*
* Displays help screens
*
HELP     JSR   HLPSTART   ;Set up and print header
         JSR   MSGOUT
         ASC   "R)ead a sector      I -Cursor up"
         HEX   8D
         ASC   "W)rite a sector     M -Cursor down"
         HEX   8D
         ASC   "T)rack entry        K -Cursor right"
         HEX   8D
         ASC   "S)ector entry       J -Cursor left"
         HEX   8D
         ASC   "A)SCII change       Arrow keys - Cursor"
         HEX   8D
         ASC   "H)ex change          in that direction"
         HEX   8D
         ASC   "F)ilter toggle      B -Cursor to start"
         HEX   8D
         ASC   "L)ower case toggle  E -Cursor to end"
         HEX   8D
         ASC   "D)rive toggle       > -Inc sector"
         HEX   8D
         ASC   "#)Slot toggle       < -Dec sector"
         HEX   8D
         ASC   "G)o to position     ? -Help"
         HEX   8D
         ASC   "N)ext sector read   ! -Free sectors"
         HEX   8D
         ASC   "P)rev sector read"
         HEX   8D
         ASC   "V)TOC sector read   Z)ero buffers"
         HEX   8D
         ASC   "C)at sector read    X)amine disassembly"
         HEX   8D
         ASC   "Q)uit program and set up re-entry vector"
         HEX   8D
         HEX   00
         JSR   HELPMSG    ;Print trailer
         JSR   CHECKEY    ;Get a key
         BCC   HELP2      ;Get next help screen
         JMP   DSPLBUFF   ;Time to leave
HELP2    JSR   HLPSTART   ;Header
         JSR   MSGOUT
         ASC   "^P -Print screen    ^N -New buff save"
         HEX   8D
         ASC   "^T -Set Track       ^O -Old buff restore"
         ASC   "^S -Set Sector      ^Z -Zero part buffer"
         ASC   "^C -Next Cat sector ^R -Set T/S and Read"
         ASC   "^F -Next file field ^I -Indirect Read"
         HEX   8D
         ASC   "^X -Test screen     SP -Continue a Read"
         HEX   8D8D
         ASC   "CTRL characters during Hex & ASCII input"
         ASC   " ^X -Cancels input"
         HEX   8D
         ASC   " ^H -Backspace (same as <--)"
         HEX   8D
         ASC   " ^M -Completes input (same as RETURN)"
         HEX   8D
         ASC   "*^O -insert next character exactly"
         HEX   8D
         ASC   "*^S -shift case (upper/lower)"
         HEX   8D
         ASC   "*^N -enter normal characters"
         HEX   8D
         ASC   "*^I -enter inverse characters"
         HEX   8D
         ASC   "*^F -enter flashing characters"
         HEX   8D
         ASC   "  ^ = Control, * = only valid for ASCII "
         HEX   8D
         HEX   00
         JSR   HELPMSG    ;Print trailer
         JSR   CHECKEY    ;Get a key
         BCS   HELP1      ;Must be done
         JMP   HELP       ;Back to first page
HELP1    JMP   DSPLBUFF
*
* Clear screen and print header
*
HLPSTART JSR   HOME
         LDA   #13        ;Cursor position
         STA   CH
         JSR   MSGOUT     ;Print the header
         ASC   "The Diskoverer"
         HEX   8D
         ASC   "   COPYRIGHT 1986 BY MICROSPARC, INC."
         HEX   8D
         HEX   00
         RTS
*
* Print trailer on bottom of help screen
*
HELPMSG  LDA   #20
         JSR   TABV
         JSR   MSGOUT
         ASC   "Press '?' for more help, CTRL P to print"
         ASC   "or any other key for the main program"
         HEX   00
         RTS
*
* Get a keystroke and branch accordingly
*
CHECKEY  JSR   CMDSETUP
         JSR   CLREOL     ;Make sure line is clear
CHECK1   BIT   KBD        ;Check for a key
         BPL   CHECK1     ;Not yet
         LDA   KBD        ;Get the keystroke
         BIT   KBDSTRB
         CMP   #$90       ;Is it control P?
         BNE   CHECK2     ;No
         LDA   #22        ;Set up for 22 lines
         STA   PRINTLEN
         LDA   #$80       ;Don't erase a cursor
         STA   PRNTBYTE
         JSR   PRINT8     ;Go to print screen
         JMP   CHECKEY    ;Back to check for a key
CHECK2   CMP   #"?"       ;Next help screen?
         BEQ   CHECK3
         CMP   #"/" ;Next help screen?
         BEQ   CHECK3
         SEC              ;Carry used as a flag
         RTS
CHECK3   CLC
         RTS
*
* Table of locations for positioning cursor
*
POSTBL   =     *
         DFB   #2
         DFB   #6
         DFB   #12
         DFB   #19
*
* Table of offset to file entry fields
*
FILETABL =     *
         DFB   $DD
         DFB   $BA
         DFB   $97
         DFB   $74
         DFB   $51
         DFB   $2E
         DFB   $0B
*
* Table of valid command keys
*
CMDTBL   =     *
         HEX   8D         ;Return
         ASC   "R"
         ASC   "Q"
         ASC   "V"
         ASC   "C"
         ASC   "."
         ASC   ">"
         ASC   "<"
         ASC   ","
         ASC   "T"
         ASC   "S"
         ASC   "#"
         ASC   "3"
         ASC   "D"
         ASC   "F"
         ASC   "L"
         HEX   81         ;Control A
         ASC   "W"
         ASC   "Z"
         ASC   "K"
         HEX   95         ;Control U
         ASC   "J"
         HEX   88         ;Control H
         ASC   "I"
         HEX   8B         ;Control K
         ASC   "M"
         HEX   8A         ;Control J
         ASC   "B"
         ASC   "E"
         ASC   "?"
         ASC   "/"
         HEX   8E         ;Control N
         HEX   8F         ;Control O
         ASC   "A"
         ASC   "G"
         ASC   "H"
         HEX   90         ;Control P
         HEX   94         ;Control T
         HEX   93         ;Control S
         HEX   92         ;Control R
         ASC   "X"
         HEX   89         ;Control I
         HEX   A0         ;Space
         HEX   83         ;Control C
         HEX   86         ;Control F
         HEX   98         ;Control X
         ASC   "N"
         ASC   "P"
         HEX   9A         ;Control Z
         ASC   "!"
         ASC   "1"
         HEX   00         ;End of table
         HEX   00000000000000000000
*
* Address - 1 for each command in command table
*
ADDRTBL  =     *
         DA    FIXSCRN-1
         DA    READ-1
         DA    QUIT-1
         DA    VTOC-1
         DA    CAT-1
         DA    INCSECT-1
         DA    INCSECT-1
         DA    DECSECT-1
         DA    DECSECT-1
         DA    TRACK-1
         DA    SECTOR-1
         DA    SLOT-1
         DA    SLOT-1
         DA    DRIVE-1
         DA    FILTER-1
         DA    LCASE-1
         DA    APFILTER-1
         DA    WRITE-1
         DA    ZERO-1
         DA    RIGHT-1
         DA    RIGHT-1
         DA    LEFT-1
         DA    LEFT-1
         DA    UP-1
         DA    UP-1
         DA    DOWN-1
         DA    DOWN-1
         DA    BEGIN-1
         DA    ENDING-1
         DA    HELP-1
         DA    HELP-1
         DA    NEW-1
         DA    OLD-1
         DA    ASCII-1
         DA    GOTO-1
         DA    HEX-1
         DA    PRINT-1
         DA    SETTRAK-1
         DA    SETSECT-1
         DA    SETREAD-1
         DA    EXAMINE-1
         DA    INDREAD-1
         DA    CONTREAD-1
         DA    CATLINK-1
         DA    NXTFILE-1
         DA    TEST-1
         DA    NEXT-1
         DA    PREVIOUS-1
         DA    ZEROPART-1
         DA    FREESPAC-1
         DA    FREESPAC-1
         HEX   00000000000000000000
         HEX   00000000000000000000
*
* Various buffer and variables useed by the program
*
*
*
DISBUFF  =     $6D00
SAVBUFF  =     $6E00
INPBUFF  =     $6F00
CURRTBL  =     $6F19
CURRSLOT =     $6F19
CURRDRIV =     $6F1A
CURRTRAK =     $6F1B
CURRSECT =     $6F1C
OLDBFTBL =     $6F1D
OLDBFPOS =     $6F1D
OLDLNPOS =     $6F1E
OLDROW   =     $6F1F
NEWBFTBL =     $6F20
NEWBFPOS =     $6F20
NEWLNPOS =     $6F21
NEWROW   =     $6F22
CURRCMD  =     NEWROW+1
RWTSCMD  =     CURRCMD+1
DISTRAK  =     RWTSCMD+1
DISSECT  =     DISTRAK+1
SAVTRAK  =     DISSECT+1
SAVSECT  =     SAVTRAK+1
SAVPOS   =     SAVSECT+1
FILTFLAG =     SAVPOS+1
LCASFLAG =     FILTFLAG+1
SLOTX16  =     LCASFLAG+1
HELPFLAG =     SLOTX16+1
ZEROFLAG =     HELPFLAG+1
PRSLOT   =     ZEROFLAG+1
SHFTFLAG =     PRSLOT+1
HEXFLAG  =     SHFTFLAG+1
INPUTLEN =     HEXFLAG+1
APFLAG   =     INPUTLEN+1
PRINTLEN =     APFLAG+1
PRNTBYTE =     PRINTLEN+1
INVFLAG  =     PRNTBYTE+1
FLSFLAG  =     INVFLAG+1
*
