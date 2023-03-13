# RISC-V assembly program for integer matrix-vector multiplication

# Define the dimensions of the matrix and vector
#define M 2
#define N 4
#define N2 2

.data

# Define the matrix as a contiguous array of signed integers
matrix1:
  .word 1, 2,
  .word 3, 4,


# Define the vector as a contiguous array of signed integers
matrix2:
  .word 3, 4,
  .word 1, 2,

  
 result:
  .word 0, 0, 0

.text

# Main function
.globl main
main:
  # Initialize variables
  addi x1, zero, M   //1  
  addi x2, zero, N   //2
  addi x13, zero, N2 //3----------------------new
 
  
  addi x14, zero, 4 // 4 x14 = 4
  NOP // 5
  NOP // 6
  NOP // 7
  mul x16, x13, x14   // 8 x16=N2*4           -------------------new
  NOP // 9
  NOP // 10
  NOP // 11
  mul x17, x16, x2  // 12N*N2*4 = x17=16
  
  mul x12, x2, x14 // 13 x12 = 4 * N
  NOP //14
  NOP // 15
  NOP // 16
  mul x14, x12, x13 // 17 x14 = 4 *N *N2 -------------new
  mul x3, x1, x12 // 18 starting address of matrix2 = M*N*4
  addi x4, x4, 0x0 // 19 starting address of matrix1 = 0
  NOP // 20
  NOP // 21
  add x5, x3, x14 // 22 starting address of result= M*N*4+N*N2*4=32

  # Outer loop: iterate over rows of matrix
  # li x6, 0   # x6 = row index
  addi x6, x6, 0 // 23
outer_loop:
  # Inner loop: iterate over columns of matrix and vector
  addi x15, zero, 0 //24  -----------------------new

inner_loop2:          ------------------------new 
  addi x7, zero, 0 // 25 

  
inner_loop:
  # Load matrix element into t8
  lw x8, 0(x4) //26
  NOP // 27
  NOP //28
  NOP //29
  NOP //30
  lw x10, 0(x3) // 31load matrix2 element

  # Multiply matrix element by vector element
  NOP
  NOP
  NOP
  mul x9, x8, x10 // 35
  NOP
  NOP
  NOP

  # Add result to accumulator register
  add x11, x11, x9 //29         68

  # Increment column index and memory address
  addi x7, x7, 1 // 30 add x by 1                   72
  addi x4, x4, 4 //31                             76
  add x3, x3, x16 //32    ------------------new  80

  # Check if inner loop is finished
  blt x7, x2, inner_loop //33         // -32   84
  
  addi x15, x15, 1 // 34 add y by 1        -----------------new  88

  // matrix2
  sub x3, x3, x17  // 35       92
  addi x3, x3, 4   // 36 96

  //matrix1
  sub x4, x4, x12 // 37 matrix1 index - length of matrix1  100


  # Store result and reset accumulator register
  sw x11, 0(x5)  // 38 104
  addi x5, x5, 4 // 39 increment result address by 4   //108
  addi x11, x0, 0 // 40 reset the accumulator          //112

     # Check if inner loop is finished
  blt x15, x13, inner_loop2             ------------------- new // 41 -68  116

  # Increment row index and reset vector memory address
  addi x6, x6, 1                                     //42 120
  mul x3, x1, x12 // 43 x3 -= 4 * N, loop back to first element in vector 124
  add x4, x4, x12 // 44 reset index of matrix1                     128

  # Check if outer loop is finished
  blt x6, x1, outer_loop                                // 45 -88    132

  # Halt the program
  j 0 // replace with dummy EOF instruction
