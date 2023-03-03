#include "src/defines.h"
.section ".text.init"
    .globl sort

/*
C equivalent (for reference)

void sort(int *p, n) {
    int swapped = 1;
    while (swapped != 0) {
        swapped = 0;
        for (int i = 0; i < n - 1; i++) {
            if (p[i] > p[i + 1]) {
                int tmp = p[i];
                p[i] = p[i + 1];
                p[i + 1] = tmp;
                swapped = 1;
            }
        }
        n = n - 1;
    }
}

Python equivalent (for reference)

# p is an array of integers
# n is the number of elements in p
#  (in other words, n == len(p))

def sort(p, n):
    swapped = True
    while swapped:                            # stop if we didn't have to make any swaps (meaning everything is in order)
        swapped = False
        for i in range(n - 1):
            if p[i] > p[i+1]:                 # if a larger element comes before a smaller element,
                p[i], p[i+1] = p[i+1], p[i]   #   swap them
                swapped = True
        n -= 1                        # optimization: after the first pass, the biggest element will be in the last place;
                                      #    after the second pass, the two biggest elements will be in the last two places;
                                      #    and so on -- so on the n-th pass we only need to consider the first n elements
*/

// a0 = address, a1 = number of elements

sort:
    addi a6, a1, -1
    li a2, 0              // Load a2 as a counter for number of passthroughs of array
    addi a5, a0, 0        // Store address in a5, a0 keeps original address

    // Edge case
    li a7, 2              // Load 2 to use it for comparison
    blt a1, a7, done      // If a1 less than 2, end program

    li a7, 0              // Initialize number of passthroughs
    bnez a1, inner        // Begin inner loop if a1 is nonzero (array has values)

outer:
    addi a5, a0, 0        // Reset address to starting array address
    addi a7, a7, 1        // Increase number of outer iterations (passthroughs) performed
    li a2, 0
    blt a7, a1, inner     // If passthroughs less than number of elements, repeat
    beq a7, a1, done      // If passthroughs equal to number of elements, finish

inner:
    lw a3, 0(a5)          // Load left entry in a3
    lw a4, 4(a5)          // Load right entry in a4

    ble a3, a4, noswap    // If a3 is less than a4 (correct order), jump to noswap

    sw a4, 0(a5)          // Store a4 value in a3 register
    sw a3, 4(a5)          // Store saved a3 value in a4 register

    // can 'j noswap' here

    addi a5, a5, 4        // Shift a5 register by one word
    addi a2, a2, 1        // Increase counter
    blt a2, a6, inner     // If more inner iterations needed, repeat Inner
    beq a2, a6, outer     // If number of inner iterations met, return to sort

noswap:
    addi a5, a5, 4        // Shift a5 register by one word
    addi a2, a2, 1        // Increase counter
    blt a2, a6, inner     // If more inner iterations needed, repeat Inner
    beq a2, a6, outer     // If number of inner iterations met, return to sort

done:
    ret


# sort:
#     // COMPLETELY SETUP, NEVER GETS CALLED AGAIN
#     beqz a1, final   // Edge case, if number of elements is zero just end it
#     li a2, 0         // Counter variable
#     addi a5, a0, 0   // ongoing current address
#     bnez a1, inner   // if nonzero array, begin iterations
#     li a7, 0
#     addi a6, a7, 1

# outer:
#     addi a7, a7, 1
#     blt a7, a6, inner
#     beq a7, a6, final

# inner:
#     lw a3, 0(a5)
#     lw a4, 4(a5)

#     blt a3, a4, noswap

#     addi a6, a3, 0            // Temporarily store a3 in a6 register
#     sw a4, 0(a5)              // Store a4 value in a3 register
#     sw a6, 4(a5)              // Store saved a3 value in a4 register

#     addi a2, a2, 1            // Increase counter
#     addi a5, a5, 4            // Shift a5 register by one word

#     blt a2, a1, inner         // If more iterations needed, repeat Inner
#     beq a2, a1, outer          // If number of iterations met, return to sort

# noswap:
#     addi a2, a2, 1            // Increase counter
#     blt a2, a1, inner

# final:
#     ret







# sort:
#     // COMPLETELY SETUP, NEVER GETS CALLED AGAIN
#     beqz a1, final   // Edge case, if number of elements is zero just end it

#     li a7, 0         // Temporary storage of number 1
#     li a2, 0         // Counter variable
#     li a3, 0         // LEFT ELEMENT
#     li a4, 0         // RIGHT ELEMENT
#     addi a5, a0, 0   // ongoing current address
#     add a7, a3, a4   // setting a7 back to zero

#     bnez a1, iterations // if nonzero array, begin iterations

# iterations:
#     addi a5, a0, 0    // Reset a2 and a5 for new iteration
#     li a2, 0

#     blt a7, a1, passthrough  // If current number of iterations is less than number of elements
#     beq a7, a1, final

# passthrough:
#     lw a3, 0(a5)
#     lw a4, 4(a5)
#     blt a4, a3, swap

#     addi a5, a5, 4           // Shift a5 register by one word
#     addi a2, a2, 1           // Add 1 to a2 passthrough counter
#     blt a2, a1, passthrough

#     addi a7, a7, 1
#     beq a2, a1, iterations

# swap:
#     addi a6, a3, 0            // Temporarily store a3 in a6 register
#     sw a4, 0(a5)              // Store a4 value in a3 register
#     sw a6, 4(a5)              // Store saved a3 value in a4 register
    
#     addi a5, a5, 4           // Shift a5 register by one word
#     addi a2, a2, 1           // Add 1 to a2 passthrough counter
#     blt a2, a1, passthrough   // If passthroughs less than number of elements, go to next passthrough

#     addi a7, a7, 1
#     beq a2, a1, iterations

# final: // Final case where we've looped N number of times
#     ret
