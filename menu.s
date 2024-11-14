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
.equ RED_LIMIT, 0x11          /* Posição máxima dos LEDs vermelhos (17) */
.equ RED_ADDRESS, 0x10000000 /* Endereço base dos LEDs vermelhos */
.equ BREAK_LINE, 0x0a        /* Código ASCII para nova linha */
.equ TIMER_ADDRESS, 0x10002000
.equ SWITCHES_ADDRESS, 0x10000040
.org 0x20

/* RTI AND TIMER EXCPETIONS */
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
  ldwio r10, 0(r14)
  beq r10, r12, DESLOCA_DIREITA
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
  movi r10, '1'              /* Verifica se o comando é '1' para animação (não implementado) */
  beq r5, r10, LEDS_ANIMATION
  movi r10, '2'              /* Verifica se o comando é '2' para temporizador (não implementado) */
  beq r5, r10, LEDS_TIMER
  br GET_JTAG                /* Retorna à espera de novos caracteres */

PUT_JTAG:
  /* Função para enviar um caractere pela JTAG UART */
  subi sp, sp, 4             /* Reserva espaço na pilha */
  stw r4, 0(sp)              /* Salva o registrador r4 */
  ldwio r4, 4(r6)            /* Lê o registro de controle da UART */
  andhi r4, r4, 0xffff       /* Verifica se há espaço de escrita */
  beq r4, r0, END_PUT        /* Se não houver espaço, ignora o caractere */
  stwio r5, 0(r6)            /* Envia o caractere pela UART */

END_PUT:
  ldw r4, 0(sp)              /* Restaura o registrador r4 */
  addi sp, sp, 4             /* Libera o espaço da pilha */
  ret                        /* Retorna da função */

LEDS_UP_DOWN:
  /* Função que determina se irá apagar ou acender os LEDs */
  ldwio r4, 0(r6)            /* Lê o próximo dado da UART */
  andi r8, r4, 0x8000        /* Verifica se há novos dados */
  beq r8, r0, LEDS_UP_DOWN   /* Se não houver dados, espera */
  andi r5, r4, 0x00ff        /* Extrai o byte menos significativo */
  call PUT_JTAG              /* Escreve o caractere */

  movi r10, '0'              /* Verifica se o comando é '0' para acender LEDs */
  beq r5, r10, LEDS_UP
  movi r10, '1'              /* Verifica se o comando é '1' para apagar LEDs */
  beq r5, r10, LEDS_DOWN

LEDS_UP:
  ldwio r4, 0(r6)            /* Lê o próximo caractere em r4 */
  andi r8, r4, 0x8000        /* Verifica se o bit mais significativo está setado */
  beq r8, r0, LEDS_UP        /* Se não estiver setado, repete a leitura */
  andi r5, r4, 0x00ff        /* Isola os 8 bits menos significativos */
  call PUT_JTAG              /* Envia o valor de r5 via JTAG */
  
LEDS_UP2:
  /* Lê o caractere correspondente ao LED a ser aceso */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_UP2
  mov r12, r5
  andi r5, r4, 0x00ff
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  muli r12, r12, 10
  add r11, r12, r5

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, FIM_UP

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  or r9, r9, r12
  stwio r9, 0(r15)

FIM_UP:
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG

LEDS_DOWN:
  /* Lógica para apagar o LED indicado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN
  andi r5, r4, 0x00ff
  call PUT_JTAG

LEDS_DOWN2:
  /* Lê o caractere correspondente ao LED a ser apagado */
  ldwio r4, 0(r6)
  andi r8, r4, 0x8000
  beq r8, r0, LEDS_DOWN2
  mov r12, r5
  andi r5, r4, 0x00ff
  call PUT_JTAG

  /* Converte caracteres ASCII para número e calcula posição do LED */
  subi r12, r12, '0'
  subi r5, r5, '0'
  muli r12, r12, 10
  add r11, r12, r5

  /* Configura o LED específico */
  movia r15, RED_ADDRESS
  movi r10, RED_LIMIT
  bgt r11, r10, FIM_DOWN

  ldwio r9, 0(r15)
  movi r12, 1
  sll r12, r12, r11
  movi r13, 0xFFFFFFFF
  sub r12, r13, r12
  and r9, r9, r12
  stwio r9, 0(r15)

FIM_DOWN:
  movia r5, BREAK_LINE
  stwio r5, 0(r6)
  br GET_JTAG

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

LEDS_TIMER:
  ret

.data
TEXT_STRING:
.asciz "\nEntre com o comando:\n> "
.end
