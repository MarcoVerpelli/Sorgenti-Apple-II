* CHAR.GEN
* Generatore di caratteri in HGR
* rodotto al mimimo preso da BIT (modificato)
*
* Per attivarlo prima 'pokkare' in 6 e 7
* l'indirizzo del set di caratteri poi PR#Astart
*
* Gestisce solo INVERSE, niente scroll e niente
* caratteri di controllo

         XC               ;siamo il //c
SETADRS  EQU   $6         ;indirizzo del set di caratteri

HBASE    EQU   $8         ;indirizzo linea HGR
CHRADRS  EQU   $1A        ;indirizzo dell'immagine del carattere
HCURS    EQU   $24        ;posizione orizzontale del cursore
BASE     EQU   $28        ;indirizzo linea testo
INVFLAG  EQU   $32        ;flag per INVERSE
aSAVE    EQU   $45        ;salva accumulatore
xSAVE    EQU   $46        ;salva registro X
ySAVE    EQU   $47        ;salva registro Y
INVMASK  EQU   $7F        ;maschera per INVERSE
PAGE     EQU   $E6        ;pagina HGR
START    EQU   $300       ;punto di ingresso
COUT1    EQU   $FDF0      ;manda char in accumulatore a schermo

         ORG   START      ;rilocabile

* Entra con il codice ASCII del carattere nell'accumulatore

         CLD              ;richiesto da BASIC.SYSTEM
         SEI              ;niente interrupt
         STA   aSAVE      ;salva i registri
         STX   xSAVE
         STY   ySAVE
         LDX   SETADRS+1  ;calcola l'indirizzo dell'immagine
         ASL              ;del carattere da visualizzare
         ASL
         BCS   :LAB1
         BPL   QUIT       ;visualizza solo i caratteri con codice
         BMI   :LAB3      ;ASCII compreso tra 32 e 127
:LAB1    BPL   :LAB2
         INX
:LAB2    INX
:LAB3    ASL
         STX   CHRADRS+1
         CLC
         ADC   SETADRS
         STA   CHRADRS
         BCC   NOCARRY1
         INC   CHRADRS+1
NOCARRY1 LDA   BASE       ;calcola l'indirizzo della linea HGR
         STA   HBASE
         LDA   BASE+1
         AND   #$03
         ORA   PAGE
         STA   HBASE+1
         LDX   #7         ;prepara il ciclo di trasferimento dal set
         LDY   HCURS      ;di caratteri allo schermo HGR
LOOP     LDA   (CHRADRS)
         BIT   INVFLAG    ;vede se e' attivo il modo INVERSE
         BMI   NORMAL
         EOR   #INVMASK   ;inverte i punti accesi/spenti
NORMAL   STA   (HBASE),Y
         INC   CHRADRS
         BNE   NOCARRY2
         INC   CHRADRS+1
NOCARRY2 LDA   HBASE+1    ;calcola indirizzo prossima riga
         CLC
         ADC   #4
         STA   HBASE+1
         DEX
         BNE   LOOP
QUIT     LDA   aSAVE      ;ripristina i registi
         LDX   xSAVE
         LDY   ySAVE
         CLI
         JMP   COUT1      ;esce via subroutine MONITOR
