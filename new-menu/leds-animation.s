.include "nios_macros.s"
.include "constants.s"
.extern PUT_JTAG
.extern GET_JTAG

.global LEDS_ANIMATION
LEDS_ANIMATION:
  movia r15, RED_ADDRESS /* Load controller address */
  movi r9, 0

  /* Start timer interrupt config */
  movia r14, TIMER_ADDRESS

  movia r8, 12000000 /* 200ms */
  stwio r8, 8(r14) /* lower counter part */

  srli r10, r8, 16 /* higher counter part */
  stwio r10, 12(r14) 

  movi r11, 0b111
  stwio r11, 4(r14) /* init timer */

  movi r14, 1  /* timer IRQ is 0 */
  wrctl ienable, r14 /*Enable timer */ 

  /* idk what is this tbh */
  movia r8, 1
  wrctl status, r8 

LOOP_TIMER:
    /* Função que determina se irá apagar ou acender os LEDs */
  ldwio r4, 0(r6)            /* Lê o próximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, LOOP_TIMER   /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere */
  movi r10, '1'              /* Verifica se o comando é '1' para apagar LEDs */
  bne r5, r10, LOOP_TIMER
  movi r14, 0  /* timer IRQ is 0 */
  wrctl ienable, r14 /*Desable timer */
  stwio r0, 0(r15) 
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG
