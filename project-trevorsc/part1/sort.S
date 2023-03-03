// TODO: Copy your quicksort.S file from Lab 2, overwriting this one

.section ".text.init"
    .globl sort

/* Python code for reference
# p is an integer array
# n is the number of elements in p: n == len(p)
def sort(p, n):
    quicksort(p, 0, n - 1)

def quicksort(p, start, end):      # Sort elements from p[start] to p[end]
    if (start < end):
        q = partition(p, start, end)
        quicksort(p, start, q - 1)
        quicksort(p, q + 1, end)

def partition(p, start, end):      # Divide p[start:end] into two subarrays, one with all
    pivot = p[end]                 # elements smaller or equal to a pivot value (the last
    i = start                      # value of input array), and another with all elements
    for j in range(start, end):    # larger than the pivot. Returns the index of the pivot.
        if (p[j] <= pivot):
            (p[i], p[j]) = (p[j], p[i]) # swap
            i += 1
    (p[i], p[end]) = (p[end], p[i]) # swap
    return i
*/

sort:
    sub t0, a2, a1
    sll a2, a2, t0
    add a1, a0, a2
    addi a2, a1, 0

mergesort:
   # Stack management
   addi sp, sp, -16             # Adjust stack pointer
   sw ra, 0(sp)                  # Load return address
   sw a0, 4(sp)                  # Load first element address
   sw a1, 8(sp)                 # Load last element address

   # Base case
   li t1, 1                      # Size of one element
   sub t0, a1, a0                # Calculate number of elements
   ble t0, t1, mergesort_end     # If only one element remains in the array, return

   srli  t0, t0, 1               # Divide array size to get half of the element
   add a1, a0, t0                # Calculate array midpoint address
   sw a1, 12(sp)                 # Store it on the stack

   jal mergesort                 # Recursive call on first half of the array

   lw a0, 12(sp)                 # Load midpoint back from the stack
   lw a1, 8(sp)                 # Load last element address back from the stack

   jal mergesort                 # Recursive call on second half of the array

   lw a0, 4(sp)                  # Load first element address back from the stack
   lw a1, 12(sp)                 # Load midpoint address back form the stack
   lw a2, 8(sp)                 # Load last element address back from the stack

   jal merge                     # Merge two sorted sub-arrays

mergesort_end:
   lw ra, 0(sp)
   addi sp, sp, 16
   ret

##
# Merge(*testArray, first, midpoint, last)
# param a0 -> first address of first array   
# param a1 -> first address of second array
# param a2 -> last address of second array
##
merge:

   # Stack management
   addi sp, sp, -16             # Adjust stack pointer
   sw ra, 0(sp)                  # Load return address
   sw a0, 4(sp)                  # Load first element of first array address
   sw a1, 8(sp)                 # Load first element of second array address
   sw a2, 12(sp)                 # Load last element of second array address

   mv s0, a0                     # First half address copy 
   mv s1, a1                     # Second half address copy

   merge_loop:

      mv t0, s0                  # copy first half position address
      mv t1, s1                  # copy second half position address
      lw t0, 0(t0)               # Load first half position value
      lw t1, 0(t1)               # Load second half position value   

      bgt t1, t0, shift_skip     # If lower value is first, no need to perform operations

      mv a0, s1                  # a0 -> element to move
      mv a1, s0                  # a1 -> address to move it to
      jal shift                  # jump to shift 
      
      addi s1, s1, 1

      shift_skip: 

            addi s0, s0, 1          # Increment first half index and point to the next element
            lw a2, 12(sp)           # Load back last element address

            bge s0, a2, merge_loop_end
            bge s1, a2, merge_loop_end
            beq x0, x0, merge_loop

      ##
      # Shift array element to a lower address
      # param a0 -> address of element to shift
      # param a1 -> address of where to move a0
      ##
      shift:

         ble a0, a1, shift_end      # Location reached, stop shifting
         addi t3, a0, -1            # Go to the previous element in the array
         lw t4, 0(a0)               # Get current element pointer
         lw t5, 0(t3)               # Get previous element pointer
         sw t4, 0(t3)               # Copy current element pointer to previous element address
         sw t5, 0(a0)               # Copy previous element pointer to current element address
         mv a0, t3                  # Shift current position back
         beq x0, x0, shift          # Loop again

      shift_end:

         ret

   merge_loop_end:

      lw ra, 0(sp)
      addi sp, sp, 16
      ret


# mergesort:
#    # Stack management
#    addi sp, sp, -32              # Adjust stack pointer
#    sw ra, 0(sp)                  # Load return address
#    sw a0, 8(sp)                  # Load first element address
#    sw a1, 16(sp)                 # Load last element address

#    # Base case
#    li t1, 1                      # Size of one element
#    sub t0, a1, a0                # Calculate number of elements
#    ble t0, t1, mergesort_end     # If only one element remains in the array, return

#    srli  t0, t0, 1               # Divide array size to get half of the element
#    add a1, a0, t0                # Calculate array midpoint address
#    sw a1, 24(sp)                 # Store it on the stack

#    jal mergesort                 # Recursive call on first half of the array

#    lw a0, 24(sp)                 # Load midpoint back from the stack
#    lw a1, 16(sp)                 # Load last element address back from the stack

#    jal mergesort                 # Recursive call on second half of the array

#    lw a0, 8(sp)                  # Load first element address back from the stack
#    lw a1, 24(sp)                 # Load midpoint address back form the stack
#    lw a2, 16(sp)                 # Load last element address back from the stack

#    jal merge                     # Merge two sorted sub-arrays

# mergesort_end:
#    lw ra, 0(sp)
#    addi sp, sp, 32
#    ret

# ##
# # Merge(*testArray, first, midpoint, last)
# # param a0 -> first address of first array   
# # param a1 -> first address of second array
# # param a2 -> last address of second array
# ##
# merge:

#    # Stack management
#    addi sp, sp, -32              # Adjust stack pointer
#    sw ra, 0(sp)                  # Load return address
#    sw a0, 8(sp)                  # Load first element of first array address
#    sw a1, 16(sp)                 # Load first element of second array address
#    sw a2, 24(sp)                 # Load last element of second array address

#    mv s0, a0                     # First half address copy 
#    mv s1, a1                     # Second half address copy

#    merge_loop:

#       mv t0, s0                  # copy first half position address
#       mv t1, s1                  # copy second half position address
#       lw t0, 0(t0)               # Load first half position value
#       lw t1, 0(t1)               # Load second half position value   

#       bgt t1, t0, shift_skip     # If lower value is first, no need to perform operations

#       mv a0, s1                  # a0 -> element to move
#       mv a1, s0                  # a1 -> address to move it to
#       jal shift                  # jump to shift 
      
#       addi s1, s1, 1

#       shift_skip: 

#             addi s0, s0, 1          # Increment first half index and point to the next element
#             lw a2, 24(sp)           # Load back last element address

#             bge s0, a2, merge_loop_end
#             bge s1, a2, merge_loop_end
#             beq x0, x0, merge_loop

#       ##
#       # Shift array element to a lower address
#       # param a0 -> address of element to shift
#       # param a1 -> address of where to move a0
#       ##
#       shift:

#          ble a0, a1, shift_end      # Location reached, stop shifting
#          addi t3, a0, -1            # Go to the previous element in the array
#          lw t4, 0(a0)               # Get current element pointer
#          lw t5, 0(t3)               # Get previous element pointer
#          sw t4, 0(t3)               # Copy current element pointer to previous element address
#          sw t5, 0(a0)               # Copy previous element pointer to current element address
#          mv a0, t3                  # Shift current position back
#          beq x0, x0, shift          # Loop again

#       shift_end:

#          ret

#    merge_loop_end:

#       lw ra, 0(sp)
#       addi sp, sp, 32
#       ret

#       mergesort:
#    # Stack management
#    addi sp, sp, -32              # Adjust stack pointer
#    sw ra, 0(sp)                  # Load return address
#    sw a0, 8(sp)                  # Load first element address
#    sw a1, 16(sp)                 # Load last element address

#    # Base case
#    li t1, 1                      # Size of one element
#    sub t0, a1, a0                # Calculate number of elements
#    ble t0, t1, mergesort_end     # If only one element remains in the array, return

#    srli  t0, t0, 1               # Divide array size to get half of the element
#    add a1, a0, t0                # Calculate array midpoint address
#    sw a1, 24(sp)                 # Store it on the stack

#    jal mergesort                 # Recursive call on first half of the array

#    lw a0, 24(sp)                 # Load midpoint back from the stack
#    lw a1, 16(sp)                 # Load last element address back from the stack

#    jal mergesort                 # Recursive call on second half of the array

#    lw a0, 8(sp)                  # Load first element address back from the stack
#    lw a1, 24(sp)                 # Load midpoint address back form the stack
#    lw a2, 16(sp)                 # Load last element address back from the stack

#    jal merge                     # Merge two sorted sub-arrays

# mergesort_end:
#    lw ra, 0(sp)
#    addi sp, sp, 32
#    ret







# // sort: a0 = start address, a1 = start index, a2 = end index
# sort:
#     ble a2, a1, done        // Exit quicksort if start index exceeds end index 

#     addi sp, sp, -20        // Move stack pointer to account for many variables
#     sw ra, 12(sp)           // Store ra, a0, a1, and a2 before calling partition
#     sw a2, 8(sp)          
#     sw a1, 4(sp)          
#     sw a0, 0(sp)           
#                             // Partition call accepts a0, a1, a2, and returns in a0 the new pivot index
#     call partition          // Partition(p, start, end) stored in a0
    
#     mv a3, a0               // Move result of Partition (pivot index) to a3
#     lw a0, 0(sp)            // Previous start address
#     lw a1, 4(sp)            // Stored start index
#     lw ra, 12(sp)           // Pop ra, a0, and a1 out from stack

#     addi a2, a3, -1         // Store end of <= Pivot section in a2
#     sw a3, 16(sp)           // Store index of beginning of >= Pivot section 

#     call sort               // Recursive Quicksort on less than Pivot section
    
#     lw a0, 0(sp)            // Pop starting address of array from stack
#     lw a1, 16(sp)           // Pop a3 (index of >= Pivot section) and store in a1 
#     lw a2, 8(sp)            // Pop end of array from stack
#     lw ra, 12(sp)         
#     addi a1, a1, 1          // Increment starting index by one
    
#     call sort               // Recursive Quicksort on greater than Pivot section

#     lw ra, 12(sp)
#     addi sp, sp, 20         // Return stack pointer to start
#     ret


# // Partition: a0 = start address, a1 = index of start, a2 = index of ending
# partition:                  // Setup variables before entering LOOP
#     addi a3, a0, 0          // Store pointer to array address in a3
#     addi a0, a1, -1         // Store starting index in a0 (need -1 for loop cause +1, endloop no +1)

#     slli a4, a2, 2          // Multiply a2 (final index) by 4 to get byte offset of last element in array
#     add	a4, a3, a4          // a3 + a4 = Address of last element in array
#     lw a5, 0(a4)            // Load pivot (last element) into a5

#     blt	a1, a2, loop        // Begin loop if first element less than final element
#     j endloop               // Otherwise, jump to end of loop


# // Loop: a1 = index of start, a3 = start address, a5 = Pivot value
# loop:
#     slli a7, a1, 2          // Get byte offset of starting element (a1) and store in a7
#     add	a7, a3, a7          // a7 -> Address of first element in array
#     lw t3, 0(a7)            // t3 -> array[a1]

#     addi a1, a1, 1          // Increment element (a1) for next loop
#     ble	t3, a5, swap        // If array[a1] <= Pivot (a5), go to swap

#     blt	a1, a2, loop        // If current index < final index, loop
#     j endloop               // Otherwise, jump to end of loop


# // Swap: a0 = most recent less than pivot value, a2 = end index, a3 = original addr., t3 = value at index a1, a7 = addr. of a1
# swap:
#     addi a0, a0, 1          // Increment less than pivot value by 1
#     slli a6, a0, 2          // Get byte offset of starting element (a0) and store in a6
#     add	a6, a3, a6          // a6 -> Address of index i in array
#     lw t1, 0(a6)            // t1 -> array[a0]

#     sw t3, 0(a6)            // array[a0] = array[a1]
#     sw t1, 0(a7)            // array[a1] = array[a0]

#     blt	a1, a2, loop        // If current index < final index, loop


# // Endloop: a0 = current start index, a3 = original addr., a4 = Pivot addr., 
# // Distinction of separate endloop section is to handle movement of the pivot/pivot address
# endloop:
#     addi t2, a0, 1          // Store index (a0 + 1) in t2
#     slli t2, t2, 2          // Get byte offset of (a0 + 1)
#     add	t2, a3, t2          // t2 -> Address of index (a0 + 1) in array
#     lw t4, 0(t2)            // array[a0 + 1] stored in t4

#     sw a5, 0(t2)            // array[a0 + 1] = a5 (Pivot) (After final <= pivot value)
#     sw t4, 0(a4)            // Save array[a0 + 1] into Pivot address
    
#     addi a0, a0, 1          // Increment index a0
#     ret

# done:
#     ret
