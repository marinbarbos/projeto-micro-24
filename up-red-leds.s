/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

/**************************************************************************/
/* Main Program                                                           */
/*   Determines the maximum number of consecutive 1s in a data word.      */
/*                                                                        */
/* r8 - Red LED address for use                                           */
/* r9 - Used to compare the input with the red led address                */
/* r10 - Used to compare the input with limit red led address             */
/* r11 - Used as input                                                    */
/* r12 - Used to save the past red leds state                             */
/**************************************************************************/
.equ RED_LIMIT, 0xF
.equ RED_ADDRESS, 0x10000000
.global _start

_start:
    movia r8, RED_ADDRESS     # Endereço base dos LEDs vermelhos
    movi r10, RED_LIMIT       # Limite de LEDs
    bgt r11, r10, END         # Se r11 > limite, salta para o fim

    # Lê o estado atual dos LEDs
    ldwio r9, 0(r8)

    # Configura o valor para acender o LED indicado em r11 sem apagar os outros
    movi r12, 1               # Inicializa r12 com 1
    sll r12, r12, r11         # Desloca o bit 1 para a posição em r11

    # Faz OR entre o valor atual (r9) e o novo LED (r12) para acender ambos
    or r9, r9, r12

    # Escreve o novo valor em r9 nos LEDs vermelhos
    stwio r9, 0(r8)

END:
    br END                    # Loop de espera
.end
