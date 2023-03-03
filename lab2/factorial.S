#include "src/defines.h"
.section ".text.init"
    .globl factorial
    .globl violation
#include "src/mul.S"

/*
Python equivalent (for reference)

def mul(a,b):
    return a * b

def factorial(n):
    running_prod = n
    for i in range(1, n):
        running_prod *= i
    return running_prod

*/

//  Input:  a0 = n
//  Output: a0

factorial:
    addi a2, a0, 0     // Set a2 to save ongoing sum

loop:
    addi a1, a0, -1    // Set a1 to a0 - 1 (Input minus 1)
    addi a0, a2, 0     // Set a0 (for mult) to a2 (ongoing product)

    beqz a1, done      // If multiplicand reaches zero, then we've reached the end

    addi sp, sp, -12    // Move stack pointer one position
    sw ra, 8(sp)
    sw a2, 4(sp)
    sw a1, 0(sp)       // Push a1 onto stack

    call mul           // Multiply a0 and a1 together
    
    // a0 is new product, load a1 = current number - 1, a2 = previous product
    lw a1, 0(sp)       // Pop values from stack
    lw a2, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12     // Move stack pointer back

    // move current product to a2, move current number - 1 to a0 for next loop
    addi a2, a0, 0     // Set a2 to product in a0
    addi a0, a1, 0

    bnez a0, loop      // If multiplicand is not zero, we continue looping

done:
    addi a0, a2, 0     // Taking ongoing product and place in return address a0
    ret
