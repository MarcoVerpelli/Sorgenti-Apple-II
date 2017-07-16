************************
*                      *
* Microsoft Easter Egg *
*                      *
************************

STRING   EQU   $F094      ;la stringa

HOME     EQU   $FC58      ;pulisce schermo
COUT1    EQU   $FDF0      ;output carattere

         ORG   $0300      ;rilocabile

         JSR   HOME
         LDX   #9
LOOP     LDA   STRING,X
         EOR   #7
         JSR   COUT1
         DEX
         BPL   LOOP
         RTS
