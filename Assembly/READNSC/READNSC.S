*********************************
*                               *
* Lettura NSC ridotta al minimo *
*                               *
*********************************

         ORG   $300

CLRROM   EQU   $CFFF
WRITENSC EQU   $C300
READNSC  EQU   $C304

         PHP
         SEI
         LDA   CLRROM
         PHA
         STA   WRITENSC
         LDA   READNSC
         LDX   #7
WRITEPAT LDA   PATTERN,X
         SEC
         ROR
:1       PHA
         LDA   #$00
         ROL
         TAY
         LDA   WRITENSC,Y
         PLA
         LSR
         BNE   :1
         DEX
         BPL   WRITEPAT
         LDX   #7
READCLK  LDY   #8
:2       LDA   READNSC
         ROR
         ROR   TIME,X
         DEY
         BNE   :2
         DEX
         BPL   READCLK
         PLA
         BMI   :3
         STA   CLRROM
:3       PLP
         RTS

PATTERN  HEX   5CA33AC55CA33AC5
TIME     EQU   *

* I valori ritornati sono in BCD

YEAR     DS    1
MONTH    DS    1
DATE     DS    1
DAY      DS    1
HOURS    DS    1
MINUTES  DS    1
SECONDS  DS    1
HUNDREDTHS DS  1
