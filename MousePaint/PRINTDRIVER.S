*****************************
*                           *
* PRINTDRIVER di MOUSEPAINT *
*                           *
* Modificato per EPSON      *
*                           *
*****************************

LN1      EQU   $0         ;indirizzo base 1a linea
LN2      EQU   $2         ;indirizzo base 2a linea
LN3      EQU   $4         ;indirizzo base 3a linea
LN4      EQU   $6         ;indirizzo base 4a linea
CSW      EQU   $36        ;characters output switch
COUNTER  EQU   $80        ;contatore linee
BY1      EQU   $81        ;1o byte
BY2      EQU   $82        ;2o byte
BY3      EQU   $83        ;3o byte
BY4      EQU   $84        ;4o byte
STRING   EQU   $82        ;puntatore alla stringa

MASK     EQU   $FF        ;maschera per il byte da stampare
SLOT     EQU   $300       ;slot della stampante (passato da MousePaint)
CROUT    EQU   $FD8E      ;stampa CR
COUT     EQU   $FDED      ;stampa carattere contenuto in Reg.A

         ORG   $8DFD      ;dove MousePaint lo carica quando serve

OST      MAC              ;output string
         LDA   #<]1
         LDX   #>]1
         JSR   OUTSTRNG
         EOM

GBT      MAC              ;get byte
         LDA   (]1),Y
         EOR   #MASK
         STA   ]2
         EOM

RBT      MAC              ;rotate bit
         LSR   ]1
         PHP
         ROR
         PLP
         ROR
         EOM

         LDA   CSW        ;salva CSW sullo stack
         PHA
         LDA   CSW+1
         PHA

         LDA   #0         ;redirige l'output su stampante
         STA   CSW
         LDA   SLOT
         STA   CSW+1

         OST   ZAPPORT    ;invia comando ZAP all'interfaccia
         JSR   CROUT

         OST   INITPRT    ;inizializza stampante
         JSR   CROUT

         LDA   #48        ;inizializza contatore blocco linee (48 * 4 = 192)
         STA   COUNTER

         LDA   #$D8       ;prepara per calcolare indirizzo prima linea
         LDY   #$A0

NXT4LNS  LDX   #$06       ;calcola indirizzo linea corrente ed indirizzo
:LAB1    CLC              ;delle 3 linee sucessive
         ADC   #$28
         BCC   :LAB2
         INY
:LAB2    STA   LN1,X
         STY   LN1+1,X
         DEX
         DEX
         BPL   :LAB1

         OST   LINEPRL    ;invia prologo, seguono dati grafici

         LDY   #0         ;indice per i bytes delle linee

LINELOOP GBT   LN1;BY1    ;prende il byte corrente dalla 1a linea
         GBT   LN2;BY2    ;prende il byte corrente dalla 2a linea
         GBT   LN3;BY3    ;prende il byte corrente dalla 3a linea
         GBT   LN4;BY4    ;prende il byte corrente dalla 4a linea

         LDX   #7         ;contatore delle 'colonne' (1 byte = 7 colonne)

BYTELOOP RBT   BY1        ;ruota i bits del 1o byte
         RBT   BY2        ;ruota i bits del 2o byte
         RBT   BY3        ;ruota i bits del 3o byte
         RBT   BY4        ;ruota i bits del 4o byte

         JSR   COUT       ;stampa la 'colonna' due volte perche'
         JSR   COUT       ;raddoppia la scala (1 pixel = 2 punti)

         DEX              ;sistema contatore 'colonne'
         BNE   BYTELOOP   ;se e' il caso ripete

         INY              ;passa ai prossimi bytes
         CPY   #40        ;40 bytes = 1 linea
         BNE   LINELOOP   ;se e' il caso ripete

         JSR   CROUT      ;ha stampato una linea grafica, manda a capo

         LDA   LN1        ;ricarica i registri con l'indirizzo della linea
         LDY   LN1+1

         DEC   COUNTER    ;sistema contatore blocco linee
         BNE   NXT4LNS    ;se e' il caso ripete per le prossime 4 linee

         OST   RESTPRT    ;alla fine, resetta la stampante
         JSR   CROUT

         PLA              ;riprende CSW dallo stack
         STA   CSW+1
         PLA
         STA   CSW

         RTS              ;fine programma

* Routine per l'output di una stringa

OUTSTRNG STA   STRING     ;salva il puntatore
         STX   STRING+1

         LDY   #0         ;indice per i caratteri della stringa

CHARLOOP LDA   (STRING),Y ;prende il carattere corrente
         BEQ   ENDSTRNG   ;zero = fine stringa
         JSR   COUT       ;stampa il carattere
         INY              ;passa al prossimo
         BNE   CHARLOOP   ;salto sempre effettuato

ENDSTRNG RTS              ;fine subroutine

ZAPPORT  HEX   09,5A,00   ;comando zap all'interfaccia
INITPRT  HEX   1B,33,18,00 ;imposta interlinea a 24/216" = 1/9"
LINEPRL  HEX   1B,2A,05,30,02,00 ;imposta grafica plotter, 560 punti grafici
RESTPRT  HEX   1B,40,00   ;resetta stampante ai default
