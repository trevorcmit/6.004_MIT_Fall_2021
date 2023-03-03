#include "src/defines.h"
.section ".text.init"
    .globl triangular

/*
Python equivalents (for reference)

def triangular(n):
    running_sum = 0
    for i in range(n+1):
        running_sum += i
    return running_sum

*/

// a0 = n

triangular:
  // YOUR CODE HERE
    li a1, 0             // Initialize a1 to be zero (running_sum)
    li a2, 0             // Counter to compare equality to
    li a3, 1             // Necessary for subtraction

    bnez a0, loop        // if a0 is not zero, head to the loop
    beqz a0, done        // Go to done if input is zero

loop:
    beqz a0, done

    addi a2, a2, 1   // Add one onto current level of pyramid
    add  a1, a1, a2  // Increment running sum with current level of pyramid
    sub  a0, a0, a3  // decrement a0 till it reaches zero

    bnez a0, loop

done:

    addi a0, a1, 0       // Make a0 equal to the running sum
    ret
