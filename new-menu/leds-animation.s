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
  movi r7, 1
  br GET_JTAG
