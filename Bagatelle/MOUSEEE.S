********************
*                  *
* Mouse Easter Egg *
*                  *
********************

         ORG   $0300      ;rilocabile

         LDX   #$C4
         LDY   #$40
         JSR   $C4F0
         RTS
