# RISC-V assembly program for integer matrix-vector multiplication

# Define the dimensions of the matrix and vector
#define M 3
#define N 4

.data

# Define the matrix as a contiguous array of signed integers
matrix:
  .word 1, 2, 3, 4
  .word 5, 6, 7, 8
  .word 9, 10, 11, 12

# Define the vector as a contiguous array of signed integers
vector:
  .word 1, 2, 3, 4
  
 result:
  .word 0, 0, 0

.text

# Main function
.globl main
main:
  # Initialize variables
  # li t0, M   # t0 = M
  addi s1, zero, M
  # li t1, N   # t1 = N
  addi s2, zero, N
  la t0, matrix   # t2 = address of matrix
  # lui t2, %hi(matrix)
  # addi t2, t2, %lo(matrix)
  la t1, vector   # t3 = address of vector
  # lui t3, %hi(vector)
  # addi t2, t2, %lo(vector)
  la t2, result   # t4 = address of result
  # lui t4, %hi(result)
  # addi t4, t4, %lo(result)
  lw t3, 0(t1)  # t5 = first element of vector

  # Outer loop: iterate over rows of matrix
  li t6, 0   # t6 = row index
outer_loop:
  # Inner loop: iterate over columns of matrix and vector
  # li t7, 0   # t7 = column index
  addi t5, zero, 0
  # addi t6, t6, 1
inner_loop:
  # Load matrix element into t8
  lw s9, 0(t0)
  lw s10, 0(t1)

  # Multiply matrix element by vector element
  mul s3, s9, s10

  # Add result to accumulator register
  add s4, s4, s3

  # Increment column index and memory address
  addi t5, t5, 1
  addi t0, t0, 4
  addi t1, t1, 4

  # Check if inner loop is finished
  blt t5, s2, inner_loop

  # Store result and reset accumulator register
  sw s4, 0(t2)
  addi t2, t2, 4
  li s4, 0

  # Increment row index and reset vector memory address
  addi t6, t6, 1
  addi t1, t1, -16

  # Check if outer loop is finished
  blt t6, s1, outer_loop

  # Halt the program
  j 0