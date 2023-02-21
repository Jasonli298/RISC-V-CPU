# RISC-V assembly program for integer matrix-vector multiplication

# Define the dimensions of the matrix and vector
#define M 3
#define N 4

.section .data

# Define the matrix as a contiguous array of signed integers
matrix:
  .word 1, 2, 3, 4
  .word 5, 6, 7, 8
  .word 9, 10, 11, 12

# Define the vector as a contiguous array of signed integers
vector:
  .word 1, 2, 3, 4

.section .text

# Main function
.globl main
main:
  # Initialize variables
  li t0, M   # t0 = M
  li t1, N   # t1 = N
  la t2, matrix   # t2 = address of matrix
  la t3, vector   # t3 = address of vector
  la t4, result   # t4 = address of result
  lw t5, 0(t3)  # t5 = first element of vector

  # Outer loop: iterate over rows of matrix
  li t6, 0   # t6 = row index
outer_loop:
  # Inner loop: iterate over columns of matrix and vector
  li t7, 0   # t7 = column index
inner_loop:
  # Load matrix element into t8
  lw t8, 0(t2)

  # Multiply matrix element by vector element
  mul t9, t8, t5

  # Add result to accumulator register
  add t10, t10, t9

  # Increment column index and memory address
  addi t7, t7, 1
  addi t2, t2, 4
  addi t3, t3, 4

  # Check if inner loop is finished
  blt t7, t1, inner_loop

  # Store result and reset accumulator register
  sw t10, 0(t4)
  li t10, 0

  # Increment row index and reset vector memory address
  addi t6, t6, 1
  addi t3, t3, -16

  # Check if outer loop is finished
  blt t6, t0, outer_loop

  # Halt the program
  j 0

# Define the result array
.section .bss
result:
  .word 0, 0, 0