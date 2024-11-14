.equ RED_LIMIT, 0xF          /* Número máximo de LEDs vermelhos (15) */
.equ RED_ADDRESS, 0x10000000 /* Endereço base dos LEDs vermelhos */
.equ BREAK_LINE, 0x0a        /* Código ASCII para nova linha */
.equ TIMER_ADDRESS, 0x10002000
.equ SWITCHES_ADDRESS, 0x10000040
.equ SEV_SEG_MASK, 0x0F
.equ SEV_SEG_ADDR, 0x10000020 /* Load 7 segments display address */
.equ LOAD_CONTR_ADDR, 0x10001000 /* Load controller address */
.equ FIRST_PUSH_BUTTON_ADDRESS, 0x1000005C