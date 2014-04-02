/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)            \
  .globl name;    /* define global symbol for 'name' */ \
  .type name, @function;  /* symbol type is function */   \
  .align 2;   /* align function definition */   \
  name:     /* function starts here */    \
  pushl $(num);             \
  jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)         \
  .globl name;              \
  .type name, @function;            \
  .align 2;             \
  name:               \
  pushl $0;             \
  pushl $(num);             \
  jmp _alltraps

#define MyFun(name, num)            \
  .text;                \
  .globl name;              \
  .type name, @function;            \
  .align 2;             \
  name:               \
  pushl $(num);             \
  jmp _alltraps;              \
  .data;                \
  .long name

#define MyFun_N(name, num)            \
  .text;                \
  .globl name;              \
  .type name, @function;            \
  .align 2;             \
  name:               \
  pushl $0;             \
  pushl $(num);             \
  jmp _alltraps;              \
  .data;                \
  .long name

#define MyNull()              \
  .data;                \
  .long 0

.data
.align 2
.globl vec
vec:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
//----------------------------------------  Lab3  ------------------------------------------------------------
/*  TRAPHANDLER_NOEC(tid0, 0)
    TRAPHANDLER_NOEC(tid1, 1)
    TRAPHANDLER_NOEC(tid2, 2)
    TRAPHANDLER_NOEC(tid3, 3)
    TRAPHANDLER_NOEC(tid4, 4)
    TRAPHANDLER_NOEC(tid5, 5)
    TRAPHANDLER_NOEC(tid6, 6)
    TRAPHANDLER_NOEC(tid7, 7)
    TRAPHANDLER(tid8, 8)
    
    TRAPHANDLER(tid10, 10)
    TRAPHANDLER(tid11, 11)
    TRAPHANDLER(tid12, 12)
    TRAPHANDLER(tid13, 13)
    TRAPHANDLER(tid14, 14)

    TRAPHANDLER_NOEC(tid16, 16)
    TRAPHANDLER(tid17, 17)
    TRAPHANDLER_NOEC(tid18, 18)
    TRAPHANDLER_NOEC(tid19, 19)
*/
//------------------------------------Lab3-Challenge----------------------------------------------------------
    MyFun_N(tid0, 0)
    MyFun_N(tid1, 1)
    MyFun_N(tid2, 2)
    MyFun_N(tid3, 3)
    MyFun_N(tid4, 4)
    MyFun_N(tid5, 5)
    MyFun_N(tid6, 6)
    MyFun_N(tid7, 7)
    MyFun(tid8, 8)
    MyNull()
    MyFun(tid10, 10)
    MyFun(tid11, 11)
    MyFun(tid12, 12)
    MyFun(tid13, 13)
    MyFun(tid14, 14)
    MyNull()
    MyFun_N(tid16, 16)
    MyFun(tid17, 17)
    MyFun_N(tid18, 18)
    MyFun_N(tid19, 19)
//------------------------------------Lab3-Challenge----------------------------------------------------------
    TRAPHANDLER_NOEC(tid48, T_SYSCALL)
//----------------------------------------  Lab3  ------------------------------------------------------------

/*
 * Lab 3: Your code here for _alltraps
 */
//----------------------------------------  Lab3  ------------------------------------------------------------
_alltraps:  
  pushl %ds
  pushl %es
  pushal
  movl $GD_KD, %eax
  movw %ax, %ds
  movw %ax, %es
  pushl %esp
  call trap
//----------------------------------------  Lab3  ------------------------------------------------------------
