/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

.include "nios_macros.s"
.include "constants.s"
.extern PUT_JTAG
.extern GET_JTAG

/**************************************************************************
* leds-animation.s
* Funcao que configura o timer da animacao
*
****************************************************************************/

.global LEDS_ANIMATION
/* Funcao da animacao dos LEDs */
LEDS_ANIMATION:
  movia r14, TIMER_ADDRESS
  movia r15, RED_ADDRESS

  /* Configuracao do Timer */
  movia r8, 12000000 /* 200ms */
  stwio r8, 8(r14) /* Parte baixa do contador */
  srli r10, r8, 16 /* Parte alta do contador */
  stwio r10, 12(r14)

  movi r11, 0b111
  stwio r11, 4(r14) /* Inicia o temporizador */

  movi r14, 1  /* IRQ do timer e 0 */
  wrctl ienable, r14 /* Habilita o IRQ 0 */

  /* Habilita interrupcoes */
  movia r8, 1
  wrctl status, r8

  movi r7, 1
  br GET_JTAG
