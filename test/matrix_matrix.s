# RISC-V assembly program for integer matrix-vector multiplication

# Define the dimensions of the matrix and vector
#define M 2
#define N 4
#define N2 2

.data

# Define the matrix as a contiguous array of signed integers
matrix:
  .word 1, 2, 3, 4
  .word 5, 6, 7, 8


# Define the vector as a contiguous array of signed integers
vector:
  .word 1, 2, 3, 4
  .word 5, 6, 7, 8
  
 result:
  .word 0, 0, 0

.text

# Main function
.globl main
main:
  # Initialize variables
  # li x4, M   # x4 = M
  addi x1, zero, M
  # li x3, N   # x3 = N
  addi x2, zero, N
  addi x14, zero, 4 // x14 = 4
  mul x12, x2, x14 // x12 = 4 * N
  mul x3, x1, x12 // starting address of vector
  # la x4, matrix   # x5 = address of matrix
  addi x4, x4, 0x0 // starting address of matrix
  # lui x5, %hi(matrix)
  # addi x5, x5, %lo(matrix)
  # la x3, vector   # t3 = address of vector
  # lui t3, %hi(vector)
  # addi x5, x5, %lo(vector)
  # la x5, result   # t4 = address of result
  add x5, x3, x12 // starting address of result
  # lui t4, %hi(result)
  # addi t4, t4, %lo(result)
  # lw t3, 0(x3)  # x7 = first element of vector

  # Outer loop: iterate over rows of matrix
  # li x6, 0   # x6 = row index
  addi x6, x6, 0
outer_loop:
  # Inner loop: iterate over columns of matrix and vector
  # li t7, 0   # t7 = column index
  addi x7, zero, 0
  # addi x6, x6, 1
inner_loop:
  # Load matrix element into t8
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
