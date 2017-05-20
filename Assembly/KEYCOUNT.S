*
* Conta e stampa su video il numero dei tasti premuti
* funziona abilitando l'interrupt della tastiera
*
* Non conta le pressioni di certi caratteri di controllo
* Il repeat automatico non influenza il conteggio
*

COUNTER  EQU   $3FB       ;contatore battute tasti
VIDEO    EQU   $400       ;angolo alto sinistro del video
CLRINT   EQU   $4FA
ENBLINT  EQU   $5FA
MLI      EQU   $BF00      ;ProDOS Machine Linguage Interface
KEYBOARD EQU   $C000      ;flag keyboard
KBDSTRB  EQU   $C010      ;reset keyboard
CLOAPPLE EQU   $C062      ;flag mela piena
ACMND    EQU   $C0AA      ;ACIA command register port #2
CR       EQU   $8D        ;codice Carriage Return
START    EQU   $300       ;indirizzo di partenza

         XC               ;siamo il //c
         ORG   START

         SEI              ;disabilita interrupt

         JSR   MLI        ;chiama ProDOS
         HEX   40         ;per eseguire ALLOC_INTERRUPT
         DW    ALLOC
         BNE   ERROR

         LDA   #%11000000 ;accende interrupt dalla tastiera
         STA   ENBLINT
         LDA   ACMND
         ORA   #%00001111
         STA   ACMND

         CLI              ;riabilita interrupt

RESET    STZ   COUNTER    ;azzera contatore battute tasti
         STZ   COUNTER+1
         STZ   COUNTER+2
         RTS

ERROR    BRK              ;qui quando errore (mai si spera !)

* Routine che serve l'interrupt

HANDLER  LDA   CLRINT     ;interrupt dalla tastiera ?
         AND   #%01000000
         BNE   KBDIRQ     ;si !
         SEC              ;non si deve gestire qui
         RTS              ;quindi esci

KBDIRQ   LDA   KEYBOARD   ;legge il carattere battuto
         CMP   #CR        ;vede se e' CR
         BNE   INCRMNT    ;no !
         LDA   CLOAPPLE   ;vede se premuto mela piena
         BPL   INCRMNT    ;no !
         BIT   KBDSTRB    ;resetta la tastiera
         JSR   RESET      ;resetta il contatore
         CLC              ;gestito interrupt
         RTS

INCRMNT  SED              ;abilita decimale
         LDX   #0         ;entra con carry set !
         TXA              ;mette zero in accumulatore
         ADC   COUNTER    ;incrementa parte bassa
         STA   COUNTER
         TXA              ;mette zero in accumulatore
         ADC   COUNTER+1  ;incrementa parte di mezzo
         STA   COUNTER+1
         TXA              ;mette zero in accumulatore
         ADC   COUNTER+2  ;incrementa parte alta
         STA   COUNTER+2
         CLD              ;fine modo decimale

         LDX   #2         ;indice per il contatore
         LDY   #0         ;indice per il video

LOOP     LDA   COUNTER,X  ;prende due cifre
         JSR   PRINT      ;le stampa su video
         DEX              ;decrementa indice contatore
         BPL   LOOP       ;ripete se non ha finito
         STZ   CLRINT     ;azzera interrupt
         CLC              ;interrupt risolto
         RTS

PRINT    PHA              ;salva nello stack
         LSR              ;isola la prima cifra
         LSR
         LSR
         LSR
         JSR   OUTCHAR    ;la stampa
         PLA              ;riprende dallo stack
         AND   #%00001111 ;isola la seconda cifra

OUTCHAR  ORA   #"0"       ;stampa una cifra su video
         STA   VIDEO,Y
         INY              ;incrementa indice video
         RTS

ALLOC    HEX   02         ;due parametri per ALLOC_INTERRUPT
         HEX   00         ;priorita' (output)
         DW    HANDLER    ;indirizzo handler
