// This program is for the benchmark testing of matrix-vector-multiplication
// meant to be easy-on-the-eye equivalent of RISC-V assembly version of the same program
#include <stdio.h>
#include <stdlib.h>

#define M 3
#define N 4
#define N2 1

int main()
{
	int mat1[M][N];
	int mat2[N][N2];
	int res[M][N2];

	int i, j, k;
	for (i = 0; i < M; i++)
	{
		for (j = 0; j < N2; j++)
		{
			res[i][j] = 0;
			for (k = 0; k < N; k++)
			{
				res[i][j] += mat1[i][k] * mat2[k][j];
			}
		}
	}
}