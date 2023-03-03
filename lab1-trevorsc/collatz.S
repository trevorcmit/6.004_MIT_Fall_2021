.section ".text.init"
    .globl collatz

/*
Python equivalent (for reference)

if n % 2 == 0:
    # n is even
    n = n / 2
else:
    # n is odd
    n = 3*n + 1

*/

collatz:

If:
  andi  a1, a0, 1
  bnez  a1, Else
Then:
  #// the word in a0 is even
  srai  a0, a0, 1 // Divide by two
  j     End
Else:
  #// the word in a0 is odd
  slli  a2, a0, 1   // Multiply by two 
  add   a0, a2, a0  // Then add another
  addi  a0, a0, 1
End:
  ret
  #// Change this line to "ret" for the
  #// program work with our test suite
