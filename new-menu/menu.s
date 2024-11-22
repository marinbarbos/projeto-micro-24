/*
Joao Pedro Brum Terra
Joao Vitor Figueredo
Marina Barbosa Americo
*/

/********************************************************************************
* Este programa utiliza a porta JTAG UART no DE2 Media Computer para implementar funcões
*
* Funcionalidades:
* 1. Envia uma mensagem inicial pela JTAG UART
* 2. Le dados de caracteres da JTAG UART
* 3. Interpreta os caracteres recebidos para acender e apagar os LEDs vermelhos
********************************************************************************/
.include "nios_macros.s"
.include "constants.s"
.extern LEDS_UP_DOWN
.extern LEDS_ANIMATION
.extern ADD_DEZENA
.extern SHOW_COUNTER
.extern LEDS_TIMER

/* RTI AND TIMER EXCPETIONS */
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

  addi r20, r0, 2
  beq r20, r19, CRONOMETRO_CONFIG # Se a parte baixa do contador for maior que 200ms, significa que estamos usando cronômetro

  # LEDS Animation Config
  movi r12, 1               # Inicializa r12 com 1
  movia r14, SWITCHES_ADDRESS /* SW slider switch base address */
  ldwio r10, 0(r14)
  beq r10, r12, DESLOCA_DIREITA
  sll r12, r12, r9         # Desloca o bit 1 para a posicao em r11
  stwio r12, 0(r15)
  addi r9, r9, 1
  ret

DESLOCA_DIREITA:
  subi r9, r9, 1
  sll r12, r12, r9         # Desloca o bit 1 para a posicao em r11
  stwio r12, 0(r15)
  ret

CRONOMETRO_CONFIG:
    movia r15, LOAD_CONTR_ADDR
    stwio r13, (r15)
    addi r7, r7, 1  /* Incrementa a unidade */
    /* Verifica se a unidade atingiu dez para incrementar a dezena */
    movi r11, 10
    bge r7, r11, ADD_DEZENA
    /* Exibe os valores nos displays */
    br SHOW_COUNTER    

.text                         /* Início do codigo executavel */
.global _start
_start:
  /* Configuracao inicial da pilha e UART */
  movia sp, 0x007FFFFC       /* Define o ponteiro de pilha para o endereco mais alto na SDRAM */
  movia r6, 0x10001000       /* Define o endereco base da JTAG UART */
  
  /* Envia uma mensagem inicial */
  movia r8, TEXT_STRING      /* Aponta para a mensagem inicial */
LOOP:
  ldb r5, 0(r8)              /* Le um byte da mensagem */
  beq r5, zero, GET_JTAG     /* Se for nulo, vai para a leitura de caracteres */
  call PUT_JTAG              /* Envia o caractere pela JTAG UART */
  addi r8, r8, 1             /* Move para o proximo caractere */
  br LOOP                    /* Continua enviando a mensagem */

.global GET_JTAG 
GET_JTAG:
  /* Le e processa caracteres da UART */
  ldwio r4, 0(r6)            /* Le o registro de dados da JTAG UART */
  andi r8, r4, 0x8000        /* Verifica se ha novos dados */
  beq r8, r0, GET_JTAG       /* Se nao houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo para obter o caractere */
  call PUT_JTAG              /* Escreve o caractere na UART */

  /* Interpreta o caractere recebido como comando */
  movi r10, '0'              /* Verifica se o comando e '0' para acender/apagar LEDs */
  beq r5, r10, LEDS_UP_DOWN
  movi r10, '1'              /* Verifica se o comando e '1' para animacao (nao implementado) */
  addi r19, r0, 1
  beq r5, r10, LEDS_ANIMATION
  movi r10, '2'              /* Verifica se o comando e '2' para temporizador (nao implementado) */
  addi r19, r0, 2
  beq r5, r10, LEDS_TIMER
  br GET_JTAG                /* Retorna à espera de novos caracteres */

.global PUT_JTAG
PUT_JTAG:
  /* Funcao para enviar um caractere pela JTAG UART */
  subi sp, sp, 4             /* Reserva espaco na pilha */
  stw r4, 0(sp)              /* Salva o registrador r4 */
  ldwio r4, 4(r6)            /* Le o registro de controle da UART */
  andhi r4, r4, 0xffff       /* Verifica se ha espaco de escrita */
  beq r4, r0, END_PUT        /* Se nao houver espaco, ignora o caractere */
  stwio r5, 0(r6)            /* Envia o caractere pela UART */

.global END_PUT
END_PUT:
  ldw r4, 0(sp)              /* Restaura o registrador r4 */
  addi sp, sp, 4             /* Libera o espaco da pilha */
  ret                        /* Retorna da funcao */


.data
TEXT_STRING:
.asciz "\nEntre com o comando:\n> "
.end
