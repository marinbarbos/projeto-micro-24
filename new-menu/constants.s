/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

/**************************************************************************
* constants.s
* Estabelece constantes, como enderecos e mascaras para uso no programa
*
****************************************************************************/
.equ RED_LIMIT, 0x11          /* Número máximo dos LEDs vermelhos (17) */
.equ RED_ADDRESS, 0x10000000  /* Endereço dos LEDs vermelhos */
.equ BREAK_LINE, 0x0a         /* Código ASCII para nova linha */
.equ TIMER_ADDRESS, 0x10002000 /* Endereço do timer */
.equ SWITCHES_ADDRESS, 0x10000040 /* Endereço dos Slide Switches */
.equ SEV_SEG_MASK, 0x0F       /* Máscara para uso do display de 7 segmentos */
.equ SEV_SEG_ADDR, 0x10000020 /* Endereço do display de 7 segmentos */
.equ LOAD_CONTR_ADDR, 0x10001000 /* Endereço do Load Controller */
.equ PUSHBUTTON_ADDR 0x10000050 /* Endereço dos Push Buttons */
.equ JTAG_UART_ADDR 0x10001000  /* Endereço da JTAG UART */
