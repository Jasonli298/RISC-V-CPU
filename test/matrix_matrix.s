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
  .word 1, 2,
  .word 3, 4,
  .word 5, 6,
  .word 7, 8,
  
 result:
  .word 0, 0, 0

.text

# Main function
.globl main
main:
  # Initialize variables
  addi x1, zero, M    0
  addi x2, zero, N    4
  addi x13, zero, N2 //----------------------new   8
 
  
  addi x14, zero, 4 // x14 = 4         12
  mul x16, x13, x14   // 2*4=8           -------------------new    16 
  mul x17, x16, x2  // N*N2*4 = x17          20 
  
  mul x12, x2, x14 // x12 = 4 * N       24
  mul x14, x12, x13 // x14 = 4 *N *N2 -------------new      28
  mul x3, x1, x12 // starting address of matrix2 = M*N*4    32 
  addi x4, x4, 0x0 // starting address of matrix1 = 0      36 
  add x5, x3, x14 // starting address of result= M*N*4+N*N2*4   40 

  # Outer loop: iterate over rows of matrix
  # li x6, 0   # x6 = row index
  addi x6, x6, 0                                  44 
outer_loop:
  # Inner loop: iterate over columns of matrix and vector
  addi x15, zero, 0   -----------------------new         48    

inner_loop2:          ------------------------new         52 
  addi x7, zero, 0

  
inner_loop:
  # Load matrix element into t8
  lw x8, 0(x4)                             56 
  lw x10, 0(x3) // load vector element      60   

  # Multiply matrix element by vector element
  mul x9, x8, x10                     64 

  # Add result to accumulator register
  add x11, x11, x9          68

  # Increment column index and memory address
  addi x7, x7, 1 // add x by 1                   72
  addi x4, x4, 4                              76
  add x3, x3, x16     ------------------new  80

  # Check if inner loop is finished
  blt x7, x2, inner_loop          // -32   84
  
  addi x15, x15, 1 // add y by 1        -----------------new  88

  // matrix2
  sub x3, x3, x17  //       92
  addi x3, x3, 4   // 96

  //matrix1
  sub x4, x4, x12 // matrix1 index - length of matrix1  100


  
  

  # Store result and reset accumulator register
  sw x11, 0(x5)                                     // 104
  addi x5, x5, 4 // increment result address by 4   //108
  addi x11, x0, 0 // reset the accumulator          //112

     # Check if inner loop is finished
  blt x15, x13, inner_loop2             ------------------- new // -68  116

  # Increment row index and reset vector memory address
  addi x6, x6, 1                                     //120
  mul x3, x1, x12 // x3 -= 4 * N, loop back to first element in vector 124
  add x4, x4, x12 // reset index of matrix1                     128

  # Check if outer loop is finished
  blt x6, x1, outer_loop                                // -88    132

  # Halt the program
  j 0 // replace with dummy EOF instruction
