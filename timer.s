/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/  


/**************************************************************************/
/* Main Program                                                           */
/*   Escreva um programa que implementa uma tarefa do estilo “maquina     */
/*   de escrever”; ou seja, leia cada caracter que e recebido pela JTAG   */
/*   UART a partir do computador hospedeiro e entao mostre o caracter     */
/*   na janela do terminal do programa monitor. Use a tecnica de polling  */
/*   para determinar se um novo caracter esta disponıvel na JTAG UART.    */
/*                                                                        */
/* r8   - Data from data register DATA field      DATA mask: 0xFF         */
/* r9   - RVALID data from data register          RVALID mask: 0x8000     */
/* r10  - RAVAIL from data & WSPACE from control  RAVAIL mask: 0xFFFF0000 */
/* r11  - AC data from controller register        AC mask: 0x400          */
/* r12  - no idea tbh                                                     */
/* r13  - aaaaaaaaaaaaaaaa                                                */
/* r14  - Timer address                                                   */
/* r15  - UART Data register address                                      */
/**************************************************************************/

/*Tratamento da interrupção */ 
# 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F
.equ RED_ADDRESS, 0x10000000
.equ TIMER_ADDRESS, 0x10002000
.equ SWITCHES_ADDRESS, 0x10000040
.org 0x20

RTI:
    rdctl et, ipending
    beq et, r0, OTHER_EXCEPTIONS

    subi ea, ea, 4    
    andi r12, et, 1
    beq r12, r0, OTHER_EXCEPTIONS
    call TIMER_EXEC

OTHER_EXCEPTIONS:
    eret

TIMER_EXEC:
  movia r14, TIMER_ADDRESS
  stwio r0, (r14)
  movi r12, 1               # Inicializa r12 com 1
  movia r14, SWITCHES_ADDRESS /* SW slider switch base address */
  ldwio r8, 0(r14)
  beq r8, r12, DESLOCA_DIREITA
  sll r12, r12, r9         # Desloca o bit 1 para a posição em r11
  stwio r12, 0(r15)
  addi r9, r9, 1
ACENDE_LEDS:
ret

DESLOCA_DIREITA:
  subi r9, r9, 1
  sll r12, r12, r9         # Desloca o bit 1 para a posição em r11
  stwio r12, 0(r15)
  br ACENDE_LEDS

/*Configura as variaveis */
.global _start
_start:

movia r15, RED_ADDRESS /* Load controller address */
movi r9, 0

/* Start timer interrupt config */
movia r14, TIMER_ADDRESS

movia r8, 25000000 /* half second */
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

LOOP:
  br LOOP

.end
