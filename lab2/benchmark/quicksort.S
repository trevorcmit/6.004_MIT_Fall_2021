.section ".text.init"
    .globl sort

// sort: Wrapper function for quicksort, algorithm begins in new 'qs' labelled section
sort:                       
  addi sp, sp, -4         // Store ra on stack
  sw ra, 0(sp)

  call qs                 // Jump to quicksort call

  lw ra, 0(sp)            // Pop ra from stack then return
  li a3, 0x40000004       // Use a3 for MMIO address for writing to console
  li a2, 0x40005000       // Load instruction counter MMIO address
  lw t0, 0(a2)            // Load instruction counter value
  sw t0, 0(a3)            // Print to console
  addi sp, sp, 4
  li	a1, 0x40006000      // Load performance counter
  lw	a2, 0(a1)           // Load instruction counter from performance counter
  sw	a2, 0(a3)           // Print to console
  ret

// qs: a0 = start address, a1 = start index, a2 = end index
qs:
  ble a2, a1, done        // Exit quicksort if start index exceeds end index 

  addi sp, sp, -20        // Move stack pointer to account for many variables
  sw ra, 12(sp)           // Store ra, a0, a1, and a2 before calling partition
  sw a2, 8(sp)          
  sw a1, 4(sp)          
  sw a0, 0(sp)      

  li t5, 0x40006004       // Add address for performance counting  
  li t0, 1                // Start performance counter
  sw t0, 0(t5)   
                          // Partition call accepts a0, a1, a2, and returns in a0 the new pivot index
  call partition          // Partition(p, start, end) stored in a0
  li t5, 0x40006004
  li t1, 0
  sw t1, 0(t5)
    
  mv a3, a0               // Move result of Partition (pivot index) to a3
  lw a0, 0(sp) 
  lw a1, 4(sp) 
  lw ra, 12(sp)           // Pop ra, a0, and a1 out from stack

  addi a2, a3, -1         // Store end of <= Pivot section in a2
  sw a3, 16(sp)           // Store index of beginning of >= Pivot section 

  call qs                 // Recursive Quicksort on less than Pivot section
    
  lw a0, 0(sp)            // Pop starting address of array from stack
  lw a1, 16(sp)           // Pop a3 (index of >= Pivot section) and store in a1 
  lw a2, 8(sp)            // Pop end of array from stack
  lw ra, 12(sp)         
  addi a1, a1, 1          // Increment starting index by one
    
  call qs                 // Recursive Quicksort on greater than Pivot section

  lw ra, 12(sp)
  addi sp, sp, 20         // Return stack pointer to start
  ret


// Partition: a0 = start address, a1 = index of start, a2 = index of ending
partition:                // Setup variables before entering LOOP
  addi a3, a0, 0          // Store pointer to array address in a3
  addi a0, a1, -1         // Store starting index in a0

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


// Swap: a0 = current start index - 1, a2 = end index, a3 = original addr., t3 = value at index a1, a7 = addr. of a1
swap:
  addi a0, a0, 1          // Increment start index 
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

  sw a5, 0(t2)            // array[a0 + 1] = a5 (Pivot)
  sw t4, 0(a4)            // Save array[a0 + 1] into Pivot address
    
  addi a0, a0, 1          // Increment index a0
  ret


done:
  ret
