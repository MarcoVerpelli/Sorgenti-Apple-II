* Calcolo e display delle generazioni di AUTOMA

NEW      EQU   $19        ;indice sulla nuova generazione
KI       EQU   $1B        ;K iniziale
XS       EQU   $1B        ;indirizzo prima cellula generazione 0
K        EQU   $1D        ;indice prima cellula intervallo
X        EQU   $1D        ;indirizzo cellula corrente generazione 0
OLD      EQU   $1D        ;indice sulla vecchia generazione
LINE     EQU   $26        ;indirizzo linea grafica
STRING   EQU   $5E        ;puntatore alla stringa passata da BASIC
RADIUS   EQU   $F9        ;raggio dell'intorno (passato da BASIC)
RANGE    EQU   $FA        ;numero-1 di cellule nell'intorno
POINT    EQU   $FB        ;punto grafico nella colonna
COLUMN   EQU   $FC        ;contatore colonne grafica
YG       EQU   $FD        ;coordinata grafica Y (e contatore generazioni)
LEN      EQU   $FE        ;lunghezza della stringa passata da BASIC
TEMP     EQU   $FF        ;usata nei calcoli
FLAG     EQU   $FF        ;flag MAIN/AUX

PAGE1    EQU   $C054      ;attiva page 1
PAGE1X   EQU   $C055      ;attiva page 1X
CHKCOM   EQU   $DEBE      ;controlla virgola
FRMEVL   EQU   $DD7B      ;valuta ogni tipo di formula
FRESTR   EQU   $E5FD      ;prende stringa, puntatore in $5E-$5F, lun. in Reg.A
COMBYT   EQU   $E74C      ;controlla virgola, prende un byte, lascia in Reg.X

         XC               ;siamo il //c
         ORG   $4000      ;in pagina grafica 2

* Pulisce OLDGEN e NEWGEN

         LDA   #<OLDGEN   ;inizio OLDGEN
         STA   OLD        ;in OLD
         LDA   #>OLDGEN
         STA   OLD+1
         LDA   #<NEWGEN   ;inizio NEWGEN
         STA   NEW        ;in NEW
         LDA   #>NEWGEN
         STA   NEW+1
CLEAR1   LDA   #0         ;deve azzerare
         STA   (OLD)      ;il vecchio
         STA   (NEW)      ;il nuovo
         INC   OLD
         BNE   OK1
         INC   OLD+1
OK1      LDA   NEW        ;controlla e incrementa NEW
         CMP   #<ENDNEW
         LDA   NEW+1
         SBC   #>ENDNEW
         INC   NEW
         BNE   OK2
         INC   NEW+1
OK2      BCC   CLEAR1     ;se NEW<=ENDNEW ripete

* Pulice RULE 22 e' la lunghezza max di RULE data da 2*(10+1)
* dove 10 e' il raggio max

         LDX   #21        ;22 cellule
CLEAR2   STZ   RULE,X     ;azzera
         DEX              ;prossima cellula
         BPL   CLEAR2

* Pulisce lo spazio di 10 cellule a destra
* e a sinistra di OLDGEN

         LDX   #9         ;10 cellule
CLEAR3   STZ   FIRSTOLD,X ;azzera a destra
         STZ   ENDOLD+1,X ;azzera a sinistra
         DEX              ;prossima cellula
         BPL   CLEAR3

* Attiva e pulisce a nero doppia alta risoluzione
* 80 colonne gia' attive

         BIT   $C050      ;attiva grafica
         BIT   $C052      ;schermo intero
         BIT   $C057      ;alta risoluzione
         BIT   $C05E      ;doppia alta risoluzione

         JSR   CLEAR      ;pulisce

* Legge e converte configurazione iniziale da BASIC
* la mette in OLDGEN e sullo schermo

         JSR   CHKCOM     ;controlla la virgola
         JSR   FRMEVL     ;valuta espressione (eventuale)
         JSR   FRESTR     ;prende stringa
         STA   LEN        ;salva lunghezza
         LSR              ;divide per due
         STA   TEMP       ;servira' tra poco
         SEC
         LDA   #<279      ;279 centro dello schermo parte bassa
         SBC   TEMP       ;sottrae lunghezza/2, ottiene centratura
         STA   X
         LDA   #>279      ;279 centro dello schermo parte alta
         SBC   #0         ;lunghezza<=255 sempre !
         STA   X+1
         CLC
         LDA   X          ;riprende parte bassa
         ADC   #<OLDGEN   ;somma inizio OLDGEN
         STA   XS
         LDA   X+1        ;riprende parte alta
         ADC   #>OLDGEN   ;come per parte bassa
         STA   XS+1
         LDA   X
         SEC
         LDY   #$FF       ;parte da -1
DIV7LOOP INY              ;incrementa risultato divisione
         SBC   #7         ;divide per 7 con sottrazioni successive
         BCS   DIV7LOOP   ;c'e' ancora da sottrarre
         SEC              ;se siamo qui era clear
         DEC   X+1        ;finito con parte bassa, ritocca alta
         BPL   DIV7LOOP   ;ancora da sottrarre
         TAX              ;usa il resto come indice
         LDA   TABLE-$F9,X ;per ottenere il valore del punto
         STA   POINT
         TYA              ;deve dividere ancora...
         LSR              ;...per due per ottenere...
         TAX              ;...la colonna
         LDA   #0
         ROL              ;il resto e' nel carry
         STA   FLAG       ;mette in FLAG
         BNE   MAIN0      ;attiva la pagina indicata da flag
         BIT   PAGE1X
         BRA   OK0
MAIN0    BIT   PAGE1
OK0      LDY   #0
LOOP1    LDA   (STRING),Y ;prende dalla stringa un carattere '0'..'9'
         AND   #$F1       ;converte in carattere '0'..'1'
         STA   (STRING),Y ;rimette a posto nella stringa
         AND   #$01       ;converte in numero 0..1
         STA   (XS),Y     ;mette in OLDGEN
         BEQ   NOPLOT1    ;se zero non occorre plottare
         LDA   POINT
         ORA   $2000,X    ;accende sempre sulla prima linea
         STA   $2000,X    ;visualizza
NOPLOT1  ASL   POINT      ;prossimo punto
         BPL   ENDPLOT1   ;se rimane nella stessa colonna
         LDA   #1         ;altrimenti...
         STA   POINT      ;...resetta...
         EOR   FLAG       ;...inverte FLAG
         STA   FLAG
         BNE   MAIN1      ;se cambia solo pagina
         INX              ;altrimenti passa prossima colonna
         BIT   PAGE1X
         BRA   ENDPLOT1
MAIN1    BIT   PAGE1
ENDPLOT1 INY              ;prossimo carattere
         CPY   LEN
         BCC   LOOP1

* Legge regola da BASIC e la mette in RULE
* lunghezza di RULE=2*(RADIUS+1)

         JSR   CHKCOM     ;controlla la virgola
         JSR   FRMEVL     ;valuta espressione (eventuale)
         JSR   FRESTR     ;prende stringa
         TAY              ;usa la lunghezza come indice
         DEY              ;dato che si parte da 0 e non da 1 come in BASIC
LOOP2    LDA   (STRING),Y ;prende dalla stringa
         EOR   #"0"       ;converte in numero
         STA   RULE,Y     ;mette in RULE
         DEY
         BPL   LOOP2

* Legge RADIUS da BASIC (deve essere<=10)

         JSR   COMBYT     ;controlla la virgola e prende un byte
         STX   RADIUS
         TXA              ;lo passa nell'accumulatore...

* Calcola RANGE=2*RADIUS

         ASL              ;...lo moltiplica per due
         STA   RANGE

* Calcola KI=OLDGEN-RADIUS (indirizzo prima cellula intervallo)

         SEC
         LDA   #<OLDGEN
         SBC   RADIUS
         STA   KI
         LDA   #>OLDGEN
         SBC   #0         ;RADIUS e' di un solo byte
         STA   KI+1

         LDA   #1         ;inizializza YG
         STA   YG         ;(1 perche' la generazione. 0 e' passata da BASIC)

* Entra qui ad ogni nuova generazione

NEXTGEN  STZ   COLUMN     ;re-inizializza COLUMN
         STZ   FLAG       ;re-inizializza FLAG
         LDA   #1
         STA   POINT      ;re-inizializza POINT

         BIT   PAGE1X     ;attiva AUX

         LDY   YG         ;prende dalla tavola inidirizzo linea grafica
         LDA   YLOW,Y
         STA   LINE
         LDA   YHIGH,Y
         STA   LINE+1

         LDA   #<NEWGEN   ;re-inizializza NEW
         STA   NEW
         LDA   #>NEWGEN
         STA   NEW+1

         LDA   KI         ;re-inizializza K
         STA   K
         LDA   KI+1
         STA   K+1

* Calcola la somma dell'intorno iniziale
* da OLDGEN[0] a OLDGEN[RADIUS]
* da OLDGEN[-RADIUS] a OLDGEN[-1]
* sono sempre=0 e non le considera

         LDX   #0         ;inizializza la somma
         LDY   RADIUS     ;reg.Y indice sull'intervallo
SUMLOOP  LDA   OLDGEN,Y   ;prende stato cellula
         BEQ   NOSUM      ;se zero non conta
         INX              ;altrimenti somma
NOSUM    DEY
         BPL   SUMLOOP

* Mette NEWGEN[NEW]=RULE[Reg.X] (nuovo stato)

GENLOOP  LDA   RULE,X     ;usa la somma come indice
         STA   (NEW)
         BEQ   NOPLOT2    ;se il nuovo stato e' zero non accende
         LDY   COLUMN
         LDA   POINT
         ORA   (LINE),Y   ;accende punto
         STA   (LINE),Y   ;visualizza

* Controlla e incrementa NEW

NOPLOT2  LDA   NEW
         CMP   #<ENDNEW
         LDA   NEW+1
         SBC   #>ENDNEW
         INC   NEW        ;incrementa NEW (indice cellula corrente nuova gen.)
         BNE   OK3
         INC   NEW+1
OK3      BCS   GENEND     ;se NEW>ENDNEW ha finito il calcolo della generaz.

* Prepara per la prossima cellula

         ASL   POINT      ;prossimo punto
         BPL   ENDPLOT2   ;se rimane nella stessa colonna
         LDA   #1         ;altrimenti...
         STA   POINT      ;...resetta...
         EOR   FLAG       ;...inverte FLAG
         STA   FLAG
         BNE   MAIN2      ;se cambia solo pagina
         INC   COLUMN     ;altrimenti passa prossima colonna
         BIT   PAGE1X     ;attiva AXU
         BRA   ENDPLOT2
MAIN2    BIT   PAGE1      ;attiva MAIN
ENDPLOT2 LDA   (K)        ;sottrae la cellula piu' a destra
         BEQ   NOSUB      ;se zero non conta
         DEX              ;altimenti sottrae
NOSUB    INC   K          ;incrementa K (indice prima cellula intorno)
         BNE   OK4
         INC   K+1
OK4      LDY   RANGE      ;somma la cellula piu' a sinistra
         LDA   (K),Y
         BEQ   GENLOOP    ;se zero non conta
         INX              ;altimenti somma
         BRA   GENLOOP

* Ha calcolato una generazione, controlla se premuto spazio

GENEND   BIT   $C000      ;legge tastiera
         BPL   COPY       ;no, continua
         BIT   $C053      ;apre finestra testo
         RTS              ;ritorna al BASIC

* Punto di rientro chiamato da BASIC

REENTER  BIT   $C052      ;chiude finestra testo

* Copia tutto NEWGEN in OLDGEN

COPY     LDA   #<OLDGEN   ;inizio OLDGEN
         STA   OLD        ;in OLD
         LDA   #>OLDGEN
         STA   OLD+1
         LDA   #<NEWGEN   ;inizio NEWGEN
         STA   NEW        ;in NEW
         LDA   #>NEWGEN
         STA   NEW+1
COPY1    LDA   (NEW)      ;carica NEW
         STA   (OLD)      ;copia in OLD
         INC   OLD        ;incrementa OLD
         BNE   OK5
         INC   OLD+1
OK5      LDA   NEW        ;controlla e incrementa NEW
         CMP   #<ENDNEW
         LDA   NEW+1
         SBC   #>ENDNEW
         INC   NEW
         BNE   OK6
         INC   NEW+1
OK6      BCC   COPY1      ;se NEW<=ENDNEW deve ripetere

* Prepara per prossima generazione

         INC   YG         ;incrementa Y (coordinata grafica)
         LDA   YG
         CMP   #191       ;se Y>191 ha riempito lo schermo...
         BCS   DOCLEAR    ;...quindi pulisce
         JMP   NEXTGEN    ;altrimenti ripete il ciclo

* Ha calcolato 192 generazioni (uno schermo), pulisce e riparte

DOCLEAR  JSR   CLEAR      ;pulisce grafica
         STZ   YG         ;re-inizializza YG
         JMP   NEXTGEN    ;riparte come se fosse la generazione 0

* Routine per pulire a nero la grafica

CLEAR    STZ   LINE       ;inizio pagina grafica $2000
         LDA   #>$2000
         STA   LINE+1
CLEAR4   LDA   #0         ;zero per pulire a nero
         TAY              ;contatore per pulire una pagina ($100 bytes)
CLEAR5   BIT   PAGE1X     ;attiva pagina 1X
         STA   (LINE),Y
         BIT   PAGE1      ;attiva pagina 1
         STA   (LINE),Y
         INY
         BNE   CLEAR5     ;ripete se e' ancora nella pagina
         INC   LINE+1     ;altrimenti passa alla prossima
         LDA   LINE+1
         CMP   #$40       ;deve pulire fino a $3FFF
         BCC   CLEAR4
         RTS              ;ritorna al chiamante

* Tabella con i valori del punto nella colonna

TABLE    HEX   01,02,04,08,10,20,40

* Tabella indirizzi 192 linee pagina grafica

YLOW     HEX   00,00,00,00,00,00,00,00,80,80,80,80,80,80,80,80
         HEX   00,00,00,00,00,00,00,00,80,80,80,80,80,80,80,80
         HEX   00,00,00,00,00,00,00,00,80,80,80,80,80,80,80,80
         HEX   00,00,00,00,00,00,00,00,80,80,80,80,80,80,80,80
         HEX   28,28,28,28,28,28,28,28,A8,A8,A8,A8,A8,A8,A8,A8
         HEX   28,28,28,28,28,28,28,28,A8,A8,A8,A8,A8,A8,A8,A8
         HEX   28,28,28,28,28,28,28,28,A8,A8,A8,A8,A8,A8,A8,A8
         HEX   28,28,28,28,28,28,28,28,A8,A8,A8,A8,A8,A8,A8,A8
         HEX   50,50,50,50,50,50,50,50,D0,D0,D0,D0,D0,D0,D0,D0
         HEX   50,50,50,50,50,50,50,50,D0,D0,D0,D0,D0,D0,D0,D0
         HEX   50,50,50,50,50,50,50,50,D0,D0,D0,D0,D0,D0,D0,D0
         HEX   50,50,50,50,50,50,50,50,D0,D0,D0,D0,D0,D0,D0,D0

YHIGH    HEX   20,24,28,2C,30,34,38,3C,20,24,28,2C,30,34,38,3C
         HEX   21,25,29,2D,31,35,39,3D,21,25,29,2D,31,35,39,3D
         HEX   22,26,2A,2E,32,36,3A,3E,22,26,2A,2E,32,36,3A,3E
         HEX   23,27,2B,2F,33,37,3B,3F,23,27,2B,2F,33,37,3B,3F
         HEX   20,24,28,2C,30,34,38,3C,20,24,28,2C,30,34,38,3C
         HEX   21,25,29,2D,31,35,39,3D,21,25,29,2D,31,35,39,3D
         HEX   22,26,2A,2E,32,36,3A,3E,22,26,2A,2E,32,36,3A,3E
         HEX   23,27,2B,2F,33,37,3B,3F,23,27,2B,2F,33,37,3B,3F
         HEX   20,24,28,2C,30,34,38,3C,20,24,28,2C,30,34,38,3C
         HEX   21,25,29,2D,31,35,39,3D,21,25,29,2D,31,35,39,3D
         HEX   22,26,2A,2E,32,36,3A,3E,22,26,2A,2E,32,36,3A,3E
         HEX   23,27,2B,2F,33,37,3B,3F,23,27,2B,2F,33,37,3B,3F

* Spazio per le generazioni e per la regola

FIRSTOLD EQU   *          ;spazio di 10 cellule a sinistra
OLDGEN   EQU   FIRSTOLD+10 ;indirizzo prima cellula vecchia generazione
ENDOLD   EQU   OLDGEN+558 ;indirizzo ultima cellula vecchia generazione
LASTOLD  EQU   ENDOLD+10  ;spazio di 10 cellule a destra
NEWGEN   EQU   LASTOLD+1  ;indirizzo prima cellula nuova generazione
ENDNEW   EQU   NEWGEN+558 ;indirizzo ultima cellula nuova generazione
RULE     EQU   ENDNEW+1   ;indirizzo regola di transizione
