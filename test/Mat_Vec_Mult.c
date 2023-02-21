// This program is for the benchmark testing of matrix-vector-multiplication
// meant to be easy-on-the-eye equivalent of RISC-V assembly version of the same program
#include <stdio.h>
#include <stdlib.h>

#define M 3
#define N 4

int main()
{
	int matrix[M][N];
	int vector[N];
	int res[N];

	int i, j; // i=rows, j=columns
	for (i = 0; i < M; i++)
	{
		res[i] = 0;
		for (j = 0; j < N; j++)
		{
			res[i] += matrix[i][j] * vector[j];
		}
	}
}