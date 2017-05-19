* Strike Eagle by Black Bag and The Six Pack's Lantern
* Of D'Gamma.
* Coded for C64CrapDebunk.Wordpress.com

* Merinl-ized, ProDOS-ized and (more) Apple-ized by MV
*
* Changed some labels because Merlin-8 max is 13 chrs
* Made it a ProDOS system file
* Changed the image: we are APPLE !!!

* Constants
rd_vbl_bar =   $c019      ; top bit clear means vblank
ptrig    =     $c070      ; clears vbl on the //c
setioudis =    $c07e
clrioudis =    $c07f
envbl    =     $c05b      ; vbl enable for the //c

txtclr   =     $c050      ; select bitmap mode
txtset   =     $c051      ; select text mode
mixclr   =     $c052      ; full screen
mixset   =     $c053      ; split screen (last four lines are text)

txtpage1 =     $c054      ; select text buffer 1 ($0400)
txtpage2 =     $c055      ; select text buffer 2 ($0x00)

lores    =     $c056      ; display low res graphics
hires    =     $c057      ; display high res graphics


* Label assignments
sine_at_1 =    $50
sine_temp =    $51

logo_x   =     $52
logo_timer =   $53
logo_count =   $54

rnd_1    =     $55
rnd_2    =     $56

scroll_count = $57
scroll_timer = $58
scroll_pos =   $59        ; two bytes used


* Work spaces for the text effect
text_buffer =  $0200
effect_buffer = $0300


         org   $2000

* read graphic data
         put   image

* restore the first 3 bytes of the image
         lda   #$00
         sta   $2000
         sta   $2001
         sta   $2002

* Entry point for the code
entry    sei


* Configure display mode
         lda   #$00
         sta   txtclr
         sta   hires
         sta   mixset

* Enable the VBL on the //c
         sta   clrioudis
         sta   envbl
         sta   setioudis

* Initialise the logo movement routine
         lda   #$00
         sta   logo_x
         sta   logo_timer
         sta   logo_count

* Clear the work spaces
         ldx   #$00
work_clear lda #$20
         sta   text_buffer,x
         lda   #$00
         sta   effect_buffer,x
         inx
         bne   work_clear

* Reset the text
         jsr   scroll_reset
         lda   #$00
         sta   scroll_count
         sta   scroll_timer

* Main loop
main_loop lda  rd_vbl_bar
         bpl   main_loop
         lda   ptrig

* Update the upper colour bars
         lda   sine_at_1
         clc
         adc   #$02
         sta   sine_at_1
         sta   sine_temp

         ldx   #$00
bar_loop_1 lda sine_temp
         clc
         adc   #$09
         sta   sine_temp
         tay
         lda   bar_sinus,y
         tay

         lda   bar_data_left+$00,y
         sta   $2000,x
         lda   bar_data_rght+$00,y
         sta   $2001,x

         lda   bar_data_left+$01,y
         sta   $2400,x
         lda   bar_data_rght+$01,y
         sta   $2401,x

         lda   bar_data_left+$02,y
         sta   $2800,x
         lda   bar_data_rght+$02,y
         sta   $2801,x

         lda   bar_data_left+$03,y
         sta   $2c00,x
         lda   bar_data_rght+$03,y
         sta   $2c01,x

         lda   bar_data_left+$04,y
         sta   $3000,x
         lda   bar_data_rght+$04,y
         sta   $3001,x

         lda   bar_data_left+$05,y
         sta   $3400,x
         lda   bar_data_rght+$05,y
         sta   $3401,x

         lda   bar_data_left+$06,y
         sta   $3800,x
         lda   bar_data_rght+$06,y
         sta   $3801,x

         lda   bar_data_left+$07,y
         sta   $3c00,x
         lda   bar_data_rght+$07,y
         sta   $3c01,x

         inx
         inx
         cpx   #$28
         bne   bar_loop_1

* Move one of the letters in the rolling logo
         ldx   logo_x
         cpx   #$21
         bcc   *+$05
         jmp   lgo_move_skip

         ldy   #$00
logo_loop_1 lda $2100,x
         sta   $2080,x
         lda   $2500,x
         sta   $2480,x
         lda   $2900,x
         sta   $2880,x
         lda   $2d00,x
         sta   $2c80,x
         lda   $3100,x
         sta   $3080,x
         lda   $3500,x
         sta   $3480,x
         lda   $3900,x
         sta   $3880,x
         lda   $3d00,x
         sta   $3c80,x

         lda   $2180,x
         sta   $2100,x
         lda   $2580,x
         sta   $2500,x
         lda   $2980,x
         sta   $2900,x
         lda   $2d80,x
         sta   $2d00,x
         lda   $3180,x
         sta   $3100,x
         lda   $3580,x
         sta   $3500,x
         lda   $3980,x
         sta   $3900,x
         lda   $3d80,x
         sta   $3d00,x

         lda   $2200,x
         sta   $2180,x
         lda   $2600,x
         sta   $2580,x
         lda   $2a00,x
         sta   $2980,x
         lda   $2e00,x
         sta   $2d80,x
         lda   $3200,x
         sta   $3180,x
         lda   $3600,x
         sta   $3580,x
         lda   $3a00,x
         sta   $3980,x
         lda   $3e00,x
         sta   $3d80,x

         lda   $2280,x
         sta   $2200,x
         lda   $2680,x
         sta   $2600,x
         lda   $2a80,x
         sta   $2a00,x
         lda   $2e80,x
         sta   $2e00,x
         lda   $3280,x
         sta   $3200,x
         lda   $3680,x
         sta   $3600,x
         lda   $3a80,x
         sta   $3a00,x
         lda   $3e80,x
         sta   $3e00,x

         lda   $2300,x
         sta   $2280,x
         lda   $2700,x
         sta   $2680,x
         lda   $2b00,x
         sta   $2a80,x
         lda   $2f00,x
         sta   $2e80,x
         lda   $3300,x
         sta   $3280,x
         lda   $3700,x
         sta   $3680,x
         lda   $3b00,x
         sta   $3a80,x
         lda   $3f00,x
         sta   $3e80,x
         lda   $2380,x
         sta   $2300,x
         lda   $2780,x
         sta   $2700,x
         lda   $2b80,x
         sta   $2b00,x
         lda   $2f80,x
         sta   $2f00,x
         lda   $3380,x
         sta   $3300,x
         lda   $3780,x
         sta   $3700,x
         lda   $3b80,x
         sta   $3b00,x
         lda   $3f80,x
         sta   $3f00,x

         lda   $2028,x
         sta   $2380,x
         lda   $2428,x
         sta   $2780,x
         lda   $2828,x
         sta   $2b80,x
         lda   $2c28,x
         sta   $2f80,x
         lda   $3028,x
         sta   $3380,x
         lda   $3428,x
         sta   $3780,x
         lda   $3828,x
         sta   $3b80,x
         lda   $3c28,x
         sta   $3f80,x

         lda   $2080,x
         sta   $2028,x
         lda   $2480,x
         sta   $2428,x
         lda   $2880,x
         sta   $2828,x
         lda   $2c80,x
         sta   $2c28,x
         lda   $3080,x
         sta   $3028,x
         lda   $3480,x
         sta   $3428,x
         lda   $3880,x
         sta   $3828,x
         lda   $3c80,x
         sta   $3c28,x

         inx
         iny
         cpy   #$08
         beq   lgo_move_skip
         jmp   logo_loop_1

* Update the rolling logo effect counters
lgo_move_skip ldx logo_timer
         inx
         cpx   #$07
         bne   lt_xb

         ldx   logo_count
         inx
         stx   logo_count

logo_xp_read lda logo_x_pos,x
         cmp   #$ff
         bne   logo_xp_okay

         ldx   #$00
         stx   logo_count
         jmp   logo_xp_read

logo_xp_okay sta logo_x

         ldx   #$00
lt_xb    stx   logo_timer

* Update the lower colour bars
         ldx   #$00
         ldy   #$26
bar_loop_2 lda $2000,x
         sta   $20a8,y
         lda   $2400,x
         sta   $24a8,y
         lda   $2800,x
         sta   $28a8,y
         lda   $2c00,x
         sta   $2ca8,y
         lda   $3000,x
         sta   $30a8,y
         lda   $3400,x
         sta   $34a8,y
         lda   $3800,x
         sta   $38a8,y
         lda   $3c00,x
         sta   $3ca8,y

         lda   $2001,x
         sta   $20a9,y
         lda   $2401,x
         sta   $24a9,y
         lda   $2801,x
         sta   $28a9,y
         lda   $2c01,x
         sta   $2ca9,y
         lda   $3001,x
         sta   $30a9,y
         lda   $3401,x
         sta   $34a9,y
         lda   $3801,x
         sta   $38a9,y
         lda   $3c01,x
         sta   $3ca9,y
         dey
         dey
         inx
         inx
         cpx   #$28
         bne   bar_loop_2

* Update the text area
         ldx   #$00
text_update lda text_buffer+$00,x
         ora   effect_buffer+$00,x
         sta   $0650,x
         lda   text_buffer+$28,x
         ora   effect_buffer+$28,x
         sta   $06d0,x
         lda   text_buffer+$50,x
         ora   effect_buffer+$50,x
         sta   $0750,x
         lda   text_buffer+$78,x
         ora   effect_buffer+$78,x
         sta   $07d0,x
         inx
         cpx   #$28
         bne   text_update

* Fetch a character of text
         ldx   scroll_timer
         inx
         cpx   #$02
         bne   st_xb

         ldx   scroll_count
         cpx   #$a0
         bcs   scroll_skip
         ldy   #$00
scroll_mread lda (scroll_pos),y
         cmp   #$ff
         bne   scroll_okay
         jsr   scroll_reset
         jmp   scroll_mread

scroll_okay sta text_buffer,x
         inc   scroll_pos+$00
         bne   *+$04
         inc   scroll_pos+$01

scroll_skip inx
         stx   scroll_count

         ldx   #$00
st_xb    stx   scroll_timer

* Randomly toggle some of the character inversions
         jsr   random
         jsr   random

         jmp   main_loop


* Randomly select a character and invert it
random   lda   rnd_1
         clc
         adc   #$01
         eor   rnd_2
         lsr
         bcc   *+$04
         ora   #$80
         ldx   rnd_2
         sta   rnd_2
         stx   rnd_1

         and   #$7f
         lda   effect_buffer+$00,x
         eor   #$80
         sta   effect_buffer+$00,x
         sta   effect_buffer+$80,x

         rts


* Subroutine to reset the scrolling message
scroll_reset lda #<scroll_text
         sta   scroll_pos+$00
         lda   #>scroll_text
         sta   scroll_pos+$01
         rts


* Labels for the colour bar data to make it easier to read
black_l  =     %00000000
black_r  =     %00000000

purple_l =     %01010101
purple_r =     %00101010

green_l  =     %00101010
green_r  =     %01010101

blue_l   =     %11010101
blue_r   =     %10101010

orange_l =     %10101010
orange_r =     %11010101

white_l  =     %01111111
white_r  =     %01111111

* Data for the colour bars (two tables for odd and even bytes)
bar_data_left dfb black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   blue_l
         dfb   black_l
         dfb   blue_l
         dfb   blue_l

         dfb   blue_l
         dfb   purple_l
         dfb   blue_l
         dfb   purple_l
         dfb   purple_l
         dfb   purple_l
         dfb   white_l
         dfb   purple_l

         dfb   white_l
         dfb   white_l
         dfb   white_l
         dfb   orange_l
         dfb   white_l
         dfb   orange_l
         dfb   orange_l
         dfb   orange_l

         dfb   green_l
         dfb   orange_l
         dfb   green_l
         dfb   green_l
         dfb   green_l
         dfb   black_l
         dfb   green_l
         dfb   black_l

         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   blue_l
         dfb   black_l
         dfb   blue_l

         dfb   blue_l
         dfb   blue_l
         dfb   purple_l
         dfb   blue_l
         dfb   purple_l
         dfb   purple_l
         dfb   purple_l
         dfb   white_l

         dfb   purple_l
         dfb   white_l
         dfb   white_l
         dfb   white_l
         dfb   orange_l
         dfb   white_l
         dfb   orange_l
         dfb   orange_l

         dfb   orange_l
         dfb   green_l
         dfb   orange_l
         dfb   green_l
         dfb   green_l
         dfb   green_l
         dfb   black_l
         dfb   green_l

         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l
         dfb   black_l

bar_data_rght dfb black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   blue_r
         dfb   black_r
         dfb   blue_r
         dfb   blue_r

         dfb   blue_r
         dfb   purple_r
         dfb   blue_r
         dfb   purple_r
         dfb   purple_r
         dfb   purple_r
         dfb   white_r
         dfb   purple_r

         dfb   white_r
         dfb   white_r
         dfb   white_r
         dfb   orange_r
         dfb   white_r
         dfb   orange_r
         dfb   orange_r
         dfb   orange_r

         dfb   green_r
         dfb   orange_r
         dfb   green_r
         dfb   green_r
         dfb   green_r
         dfb   black_r
         dfb   green_r
         dfb   black_r

         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   blue_r
         dfb   black_r
         dfb   blue_r

         dfb   blue_r
         dfb   blue_r
         dfb   purple_r
         dfb   blue_r
         dfb   purple_r
         dfb   purple_r
         dfb   purple_r
         dfb   white_r

         dfb   purple_r
         dfb   white_r
         dfb   white_r
         dfb   white_r
         dfb   orange_r
         dfb   white_r
         dfb   orange_r
         dfb   orange_r

         dfb   orange_r
         dfb   green_r
         dfb   orange_r
         dfb   green_r
         dfb   green_r
         dfb   green_r
         dfb   black_r
         dfb   green_r

         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r
         dfb   black_r

* Sine curve for the bar movement
bar_sinus dfb  $3d,$3d,$3d,$3d,$3d,$3d,$3d,$3d
         dfb   $3d,$3d,$3d,$3c,$3c,$3c,$3c,$3b
         dfb   $3b,$3b,$3b,$3a,$3a,$39,$39,$39
         dfb   $38,$38,$37,$37,$36,$36,$35,$35
         dfb   $34,$34,$33,$33,$32,$32,$31,$30
         dfb   $30,$2f,$2e,$2e,$2d,$2c,$2c,$2b
         dfb   $2a,$2a,$29,$28,$27,$27,$26,$25
         dfb   $25,$24,$23,$22,$21,$21,$20,$1f

         dfb   $1e,$1e,$1d,$1c,$1b,$1b,$1a,$19
         dfb   $18,$18,$17,$16,$15,$15,$14,$13
         dfb   $13,$12,$11,$10,$10,$0f,$0e,$0e
         dfb   $0d,$0d,$0c,$0b,$0b,$0a,$0a,$09
         dfb   $09,$08,$07,$07,$06,$06,$06,$05
         dfb   $05,$04,$04,$03,$03,$03,$02,$02
         dfb   $02,$02,$01,$01,$01,$01,$00,$00
         dfb   $00,$00,$00,$00,$00,$00,$00,$00

         dfb   $00,$00,$00,$00,$00,$00,$00,$00
         dfb   $00,$00,$00,$01,$01,$01,$01,$02
         dfb   $02,$02,$03,$03,$03,$04,$04,$04
         dfb   $05,$05,$06,$06,$07,$07,$08,$08
         dfb   $09,$09,$0a,$0a,$0b,$0c,$0c,$0d
         dfb   $0d,$0e,$0f,$0f,$10,$11,$11,$12
         dfb   $13,$13,$14,$15,$16,$16,$17,$18
         dfb   $19,$19,$1a,$1b,$1c,$1c,$1d,$1e

         dfb   $1f,$1f,$20,$21,$22,$22,$23,$24
         dfb   $25,$25,$26,$27,$28,$28,$29,$2a
         dfb   $2b,$2b,$2c,$2d,$2d,$2e,$2f,$2f
         dfb   $30,$31,$31,$32,$32,$33,$33,$34
         dfb   $35,$35,$36,$36,$37,$37,$38,$38
         dfb   $38,$39,$39,$3a,$3a,$3a,$3b,$3b
         dfb   $3b,$3b,$3c,$3c,$3c,$3c,$3d,$3d
         dfb   $3d,$3d,$3d,$3d,$3d,$3d,$3d,$3d

* X offsets for the rolling logo effect
logo_x_pos dfb $00,$fe,$08,$fe,$10,$fe,$18,$fe
         dfb   $20,$fe,$fe,$fe,$20,$fe,$10,$fe
         dfb   $00,$fe,$18,$fe,$08,$fe,$fe,$fe
         dfb   $10,$fe,$08,$fe,$18,$fe,$00,$fe
         dfb   $20,$fe,$fe,$fe,$fe,$20,$fe,$18
         dfb   $fe,$10,$fe,$08,$fe,$00,$fe,$fe
         dfb   $fe,$20,$18,$10,$08,$00,$08,$10
         dfb   $18,$20,$18,$10,$08,$00,$fe,$fe

         dfb   $ff              ; end of data marker

scroll_text inv " WELCOME TO   -=- F15 D'GAMMA CLONE -=- "
         inv   "                                        "
         inv   "      CODING AND GRAPHICS BY T.M.R      "
         inv   " RELEASED BY C64CD ON THE 19TH MAY 2016 "

         inv   " BASED ON THE APPLE II CRACK INTROS FOR "
         inv   "   F-15 STRIKE EAGLE BY BLACK BAG AND   "
         inv   "  LANTERN OF D'GAMMA FROM THE SIX PACK  "
         inv   " (WITH A FEW EXTRA C64 INFLUENCES TOO!) "

         inv   "                                        "
         inv   "                                        "
         inv   "                                        "
         inv   "                                        "

         inv   "THIS CODE USES $C019 TO SYNCHRONISE WITH"
         inv   " THE VERTICAL BLANK - THAT MAY NOT WORK "
         inv   "ON ALL MODELS OF APPLE II, BUT IF ANYONE"
         inv   "TESTS ON REAL HARDWARE I'D LIKE TO KNOW!"

         inv   " EMAIL ME AT TMR.C64CD@GMAIL.COM TO SAY "
         inv   "   IF THE CODE RAN, WHICH MODEL OF A2   "
         inv   "  AND WHICH CARDS ARE PRESENT, PLEASE!  "
         inv   "                                        "

         inv   "                                        "
         inv   "                                        "
         inv   "                                        "
         inv   "                                        "

         inv   "C64CD ALPHABETICALLY SORTED GREETINGS TO"
         inv   "                                        "
         inv   "  1001 CREW   ASH AND DAVE   BLACK BAG  "
         inv   "         BORDERZONE DEZIGN TEAM         "

         inv   "    FOUR HORSEMEN  OF THE APOCALYPSE    "
         inv   "HAPPY DEMOMAKER  HARLOW CRACKING SERVICE"
         inv   "  MEAN TEAM     PAUL, SHANDOR AND MATT  "
         inv   "PULSE PRODUCTIONS  RESET 86  ROB HUBBARD"

         inv   "   SCOOP     STOAT AND TIM    TANGENT   "
         inv   " THALAMUS     THE COMMANDOS     THE GPS "
         inv   "  THE SIX PACK   WE MUSIC   XESS   YAK  "
         inv   "                                        "

         inv   "                                        "
         inv   "                                        "
         inv   "                                        "
         inv   "                                        "

         inv   "AND WE'LL FINISH ON A QUICK WEBSITE PLUG"
         inv   "                                        "
         inv   "   VISIT  C64CRAPDEBUNK.WORDPRESS.COM   "
         inv   "        BECAUSE.... WELL, STUFF!        "

         inv   "                                        "
         inv   "                                        "
         inv   "                                        "
         inv   "                                        "

         dfb   $ff        ; end of text marker

         typ   $ff        ; system file type
         sav   fdclone.system
