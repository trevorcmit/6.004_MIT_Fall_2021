#include "src/defines.h"
.section ".text.init"
    .globl sort
    .globl kth_smallest
    .globl violation

/*
QUICKSORT & PARTITION
C implementation (for reference)

int partition(int* p, int start, int end) {
    int x = p[end]; // select pivot
    int j, tmp, i = start - 1;
    for (j = start; j < end; j++) {
        if (p[j] <= x) {
            i++;
            tmp = p[i];
            p[i] = p[j];
            p[j] = tmp;
        }
    }
    tmp = p[i + 1];
    p[i + 1] = p[end];
    p[end] = tmp;
    return i + 1;
}

void quicksort(int* p, int start, int end) {
    if (start < end) {
        int q = partition(p, start, end);
        quicksort(p, start, q - 1);
        quicksort(p, q + 1, end);
    }
}

Python implementation (for reference)

def partition(p, start, end):
    x = p[end]
    i = (start - 1)
    for j in range(start, end):
        if p[j] <= x:
            i = i + 1
            tmp = p[i]
            p[i] = p[j]
            p[j] = tmp

    tmp = p[i + 1]
    p[i + 1] = p[end]
    p[end] = tmp
    return i + 1

def quicksort(p, start, end):
    if start < end:
        q = partition(p, start, end)
        quicksort(p, start, q - 1)
        quicksort(p, q + 1, end)

*/


// sort: a0 = start address, a1 = start index, a2 = end index
sort:
    ble a2, a1, done        // Exit quicksort if start index exceeds end index 

    addi sp, sp, -20        // Move stack pointer to account for many variables
    sw ra, 12(sp)           // Store ra, a0, a1, and a2 before calling partition
    sw a2, 8(sp)          
    sw a1, 4(sp)          
    sw a0, 0(sp)           
                            // Partition call accepts a0, a1, a2, and returns in a0 the new pivot index
    call partition          // Partition(p, start, end) stored in a0
    
    mv a3, a0               // Move result of Partition (pivot index) to a3
    lw a0, 0(sp)            // Previous start address
    lw a1, 4(sp)            // Stored start index
    lw ra, 12(sp)           // Pop ra, a0, and a1 out from stack

    addi a2, a3, -1         // Store end of <= Pivot section in a2
    sw a3, 16(sp)           // Store index of beginning of >= Pivot section 

    call sort               // Recursive Quicksort on less than Pivot section
    
    lw a0, 0(sp)            // Pop starting address of array from stack
    lw a1, 16(sp)           // Pop a3 (index of >= Pivot section) and store in a1 
    lw a2, 8(sp)            // Pop end of array from stack
    lw ra, 12(sp)         
    addi a1, a1, 1          // Increment starting index by one
    
    call sort               // Recursive Quicksort on greater than Pivot section

    lw ra, 12(sp)
    addi sp, sp, 20         // Return stack pointer to start
    ret


// Partition: a0 = start address, a1 = index of start, a2 = index of ending
partition:                  // Setup variables before entering LOOP
    addi a3, a0, 0          // Store pointer to array address in a3
    addi a0, a1, -1         // Store starting index in a0 (need -1 for loop cause +1, endloop no +1)

    slli a4, a2, 2          // Multiply a2 (final index) by 4 to get byte offset of last element in array
    add	a4, a3, a4          // a3 + a4 = Address of last element in array
    lw a5, 0(a4)            // Load pivot (last element) into a5

    blt	a1, a2, loop        // Begin loop if first element less than final element
    j endloop               // Otherwise, jump to end of loop


// Loop: a1 = index of start, a3 = start address, a5 = Pivot value
loop:
    slli a7, a1, 2          // Get byte offset of starting element (a1) and store in a7
    add	a7, a3, a7          // a7 -> Address of first element in array
    lw t3, 0(a7)            // t3 -> array[a1]

    addi a1, a1, 1          // Increment element (a1) for next loop
    ble	t3, a5, swap        // If array[a1] <= Pivot (a5), go to swap

    blt	a1, a2, loop        // If current index < final index, loop
    j endloop               // Otherwise, jump to end of loop


// Swap: a0 = most recent less than pivot value, a2 = end index, a3 = original addr., t3 = value at index a1, a7 = addr. of a1
swap:
    addi a0, a0, 1          // Increment less than pivot value by 1
    slli a6, a0, 2          // Get byte offset of starting element (a0) and store in a6
    add	a6, a3, a6          // a6 -> Address of index i in array
    lw t1, 0(a6)            // t1 -> array[a0]

    sw t3, 0(a6)            // array[a0] = array[a1]
    sw t1, 0(a7)            // array[a1] = array[a0]

    blt	a1, a2, loop        // If current index < final index, loop


// Endloop: a0 = current start index, a3 = original addr., a4 = Pivot addr., 
// Distinction of separate endloop section is to handle movement of the pivot/pivot address
endloop:
    addi t2, a0, 1          // Store index (a0 + 1) in t2
    slli t2, t2, 2          // Get byte offset of (a0 + 1)
    add	t2, a3, t2          // t2 -> Address of index (a0 + 1) in array
    lw t4, 0(t2)            // array[a0 + 1] stored in t4

    sw a5, 0(t2)            // array[a0 + 1] = a5 (Pivot) (After final <= pivot value)
    sw t4, 0(a4)            // Save array[a0 + 1] into Pivot address
    
    addi a0, a0, 1          // Increment index a0
    ret

done:
    ret

/*
Kth SMALLEST

Python implementation (for reference)

# array is the sorted array from sort
# gets index k from the user and prints array[k]
# returns nothing

def kth_smallest(array):
    x = input("enter the index to print\n")
    print array[x]
    return

*/

//  Input:  a0 = address of sorted array
kth_smallest:
    li a1, 0x40004000        // Use a1 for MMIO address for reading from console
    lw a2, 0(a1)             // Read input from a1 address and store in a2
    slli a1, a2, 2           // Get byte offset for index a2 and store in a1
    add	a1, a0, a1           // Add byte offset to original address for to get address of index
    lw a2, 0(a1)             // Load kth smallest value into a2
    li a1, 0x40000004        // Use a1 for MMIO address for writing to console
    sw a2, 0(a1)             // Send kth smallest value (a2) to console through address a1 
    ret
