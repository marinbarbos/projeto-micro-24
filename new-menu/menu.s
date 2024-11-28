/*
João Pedro Brum Terra
João Vitor Figueredo
Marina Barbosa Américo
*/

/********************************************************************************
* Este programa utiliza a porta JTAG UART no DE2 Media Computer para implementar funções
*
* Funcionalidades:
* 1. Envia uma mensagem inicial pela JTAG UART
* 2. Lê dados de caracteres da JTAG UART
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
EXCEPTION_HANDLER:
  subi sp, sp, 16 /* make room on the stack */
  stw et, 0(sp)
  rdctl et, ctl4
  beq et, r0, SKIP_EA_DEC /* interrupt is not external */
  subi ea, ea, 4 /* must decrement ea by one instruction */
  /* for external interrupts, so that the */
  /* interrupted instruction will be run after eret */

SKIP_EA_DEC:
  stw ea, 4(sp) /* save all used registers on the Stack */
  stw ra, 8(sp) /* needed if call inst is used */
  stw r22, 12(sp)
  rdctl et, ctl4
  bne et, r0, CHECK_LEVEL_0 /* exception is an external interrupt */

NOT_EI: /* exception must be unimplemented instruction or TRAP */
  br END_ISR /* instruction. This code does not handle those cases */

CHECK_LEVEL_0: /* interval timer is interrupt level 0 */
  andi r22, et, 0b1
  beq r22, r0, CHECK_LEVEL_1
  call INTERVAL_TIMER_ISR
  br END_ISR

CHECK_LEVEL_1: /* pushbutton port is interrupt level 1 */
  andi r22, et, 0b10
  beq r22, r0, END_ISR /* other interrupt levels are not handled in this code */
  call PUSHBUTTON_ISR

END_ISR:
  ldw et, 0(sp) /* restore all used register to previous values */
  ldw ea, 4(sp)
  ldw ra, 8(sp) /* needed if call inst is used */
  ldw r22, 12(sp)
  addi sp, sp, 16
  eret

/* Sub Rotina - de display */
.org 0x100    
PUSHBUTTON_ISR:
  subi sp, sp, 20 /* reserve space on the stack */
  stw ra, 0(sp)
  stw r10, 4(sp)
  stw r11, 8(sp)
  stw r12, 12(sp)
  stw r13, 16(sp)
  movia r10, 0x10000050 /* base address of pushbutton KEY parallel port */
  ldwio r11, 0xC(r10) /* read edge capture register */
  stwio r0, 0xC(r10) /* clear the interrupt */  
  beq r0, r19, DESPAUSA
  mov r19, r0
  br END_PUSHBUTTON_ISR
DESPAUSA:
  movi r19, 1
  br END_PUSHBUTTON_ISR

END_PUSHBUTTON_ISR:
  ldw ra, 0(sp) /* Restore all used register to previous values */
  ldw r10, 4(sp)
  ldw r11, 8(sp)
  ldw r12, 12(sp)
  ldw r13, 16(sp)
  addi sp, sp, 20
  ret

INTERVAL_TIMER_ISR:
  movia r14, TIMER_ADDRESS
  stwio r0, (r14)

  addi r20, r0, 2
  beq r20, r7, CRONOMETRO_CONFIG # Se a parte baixa do contador for maior que 200ms, significa que estamos usando cronômetro

  # LEDS Animation Config
  movi r12, 1               # Inicializa r12 com 1
  movia r14, SWITCHES_ADDRESS /* SW slider switch base address */
  ldwio r10, 0(r14)
  beq r10, r12, DESLOCA_DIREITA
  sll r12, r12, r9         # Desloca o bit 1 para a posição em r11
  stwio r12, 0(r15)
  addi r9, r9, 1
  ret

DESLOCA_DIREITA:
  subi r9, r9, 1
  sll r12, r12, r9         # Desloca o bit 1 para a posição em r11
  stwio r12, 0(r15)
  ret

CRONOMETRO_CONFIG:
    add r23, r23, r19  /* Incrementa a unidade */
    /* Verifica se a unidade atingiu dez para incrementar a dezena */
    movi r11, 10
    bge r23, r11, ADD_DEZENA
    /* Exibe os valores nos displays */
    br SHOW_COUNTER    

.text                         /* Início do código executável */
.global _start
_start:
  /* Configuração inicial da pilha e UART */
  movia sp, 0x007FFFFC       /* Define o ponteiro de pilha para o endereço mais alto na SDRAM */
  movia r6, 0x10001000       /* Define o endereço base da JTAG UART */
  
  /* Envia uma mensagem inicial */
  movia r8, TEXT_STRING      /* Aponta para a mensagem inicial */
LOOP:
  ldb r5, 0(r8)              /* Lê um byte da mensagem */
  beq r5, zero, GET_JTAG     /* Se for nulo, vai para a leitura de caracteres */
  call PUT_JTAG              /* Envia o caractere pela JTAG UART */
  addi r8, r8, 1             /* Move para o próximo caractere */
  br LOOP                    /* Continua enviando a mensagem */

.global GET_JTAG 
GET_JTAG:
  /* Lê e processa caracteres da UART */
  ldwio r4, 0(r6)            /* Lê o registro de dados da JTAG UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, GET_JTAG       /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo para obter o caractere */
  call PUT_JTAG              /* Escreve o caractere na UART */

  /* Interpreta o caractere recebido como comando */
  movi r10, '0'              /* Verifica se o comando é '0' para acender/apagar LEDs */
  beq r5, r10, LEDS_UP_DOWN
  movi r10, '1'              /* Verifica se o comando é '1' para animação */
  beq r5, r10, FIRST_FUNCTION
  movi r10, '2'              /* Verifica se o comando é '2' para temporizador */
  beq r5, r10, SECOND_FUNCTION
  br GET_JTAG                /* Retorna à espera de novos caracteres */

.global PUT_JTAG
PUT_JTAG:
  /* Função para enviar um caractere pela JTAG UART */
  subi sp, sp, 4             /* Reserva espaço na pilha */
  stw r4, 0(sp)              /* Salva o registrador r4 */
  ldwio r4, 4(r6)            /* Lê o registro de controle da UART */
  andhi r4, r4, 0xffff       /* Verifica se há espaço de escrita */
  beq r4, r0, END_PUT        /* Se não houver espaço, ignora o caractere */
  stwio r5, 0(r6)            /* Envia o caractere pela UART */

.global END_PUT
END_PUT:
  ldw r4, 0(sp)              /* Restaura o registrador r4 */
  addi sp, sp, 4             /* Libera o espaço da pilha */
  ret                        /* Retorna da função */

FIRST_FUNCTION:
  /* Lê e processa caracteres da UART */
  ldwio r4, 0(r6)            /* Lê o registro de dados da JTAG UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, FIRST_FUNCTION       /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo para obter o caractere */
  call PUT_JTAG              /* Escreve o caractere na UART */
  /* Interpreta o caractere recebido como comando */
  movi r10, '0'              /* Verifica se o comando é '0' para acender/apagar LEDs */
  beq r5, r10, LEDS_ANIMATION
  movi r10, '1'
  beq r5, r10, STOP_ANIMATION
  br GET_JTAG

STOP_ANIMATION:
  movi r14, 0  /* timer IRQ is 0 */
  wrctl ienable, r14 /*Desable timer */
  stwio r0, 0(r15) 
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG

SECOND_FUNCTION:
  /* Lê e processa caracteres da UART */
  ldwio r4, 0(r6)            /* Lê o registro de dados da JTAG UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, SECOND_FUNCTION       /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo para obter o caractere */
  call PUT_JTAG              /* Escreve o caractere na UART */
  /* Interpreta o caractere recebido como comando */
  movi r10, '0'              /* Verifica se o comando é '0' para acender/apagar LEDs */
  beq r5, r10, LEDS_TIMER
  movi r10, '1'
  beq r5, r10, STOP_TIMER
  br GET_JTAG
  
STOP_TIMER:
  mov r23, r0        /* unidade */
  mov r16, r0       /* dezena */
  mov r17, r0       /* centena */
  mov r18, r0       /* milhar */
  call SHOW_COUNTER
  movia r5, BREAK_LINE
  stwio r5, 0(r6)  
  movi r14, 0  /* timer IRQ is 0 */
  wrctl ienable, r14 /*Enable timer */ 
  br GET_JTAG

.data
TEXT_STRING:
.asciz "\nEntre com o comando:\n> "
.end
