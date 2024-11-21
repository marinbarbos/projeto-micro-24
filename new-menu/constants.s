.equ RED_LIMIT, 0x11                        /* Contagem maxima dos LEDs (17) */
.equ RED_ADDRESS, 0x10000000                /* Endereco dos LEDs vermelhos */
.equ BREAK_LINE, 0x0a                       /* Codigo ASCII para New line(\n) */
.equ TIMER_ADDRESS, 0x10002000              /* Endereco do Clock */
.equ SWITCHES_ADDRESS, 0x10000040           /* Endereco dos Toggle Switches */
.equ SEV_SEG_MASK, 0x0F                     /* Mascara para o uso do display de 7 segmentos */
.equ SEV_SEG_ADDR, 0x10000020               /* Endereco do display de 7 segmentos */
.equ LOAD_CONTR_ADDR, 0x10001000            /* Endereco do Load Controller */