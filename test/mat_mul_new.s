
main:
  # Initialize variables
  addi x1, zero, M
  addi x2, zero, N
  addi x14, zero, 4 // x14 = 4
  mul x12, x2, x14 // x12 = 4 * N
  mul x3, x1, x12 // starting address of vector
  addi x4, x4, 0x0 // starting address of matrix
  add x5, x3, x12 // starting address of result
  addi x6, x6, 0
  
outer_loop:
  addi x7, zero, 0
inner_loop:
  lw x8, 0(x4)
  lw x10, 0(x3) // load vector element

  # Multiply matrix element by vector element
  mul x9, x8, x10

  # Add result to accumulator register
  add x11, x11, x9

  # Increment column index and memory address
  addi x7, x7, 1
  addi x4, x4, 4
  addi x3, x3, 4

  # Check if inner loop is finished
  blt x7, x2, inner_loop

  # Store result and reset accumulator register
  sw x11, 0(x5)
  addi x5, x5, 4 // increment result address by 4
  addi x11, x0, 0 // reset the accumulator

  # Increment row index and reset vector memory address
  addi x6, x6, 1
  mul x3, x1, x12 // x3 -= 4 * N, loop back to first element in vector

  # Check if outer loop is finished
  blt x6, x1, outer_loop

  # Halt the program
  j 0 // replace with dummy EOF instruction
