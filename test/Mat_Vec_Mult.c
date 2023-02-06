// This program is for the benchmark testing of matrix-vector-multiplication
// meant to be easy-on-the-eye equivalent of RISC-V assembly version of the same program
#include <stdio.h>
#include <stdlib.h>

int N; // the number of columns in the matrix and the number of rows in the vector
int R; // the number of rows in the matrix

void MatVecMult(int matrix[R][N], const int vector[N], int res[N])
{
	int i, j; // i=rows, j=columns
	for (i = 0; i < R; i++)
	{
		res[i] = 0;
		for (j = 0; j < N; j++)
		{
			res[i] += matrix[i][j] * vector[j];
		}
	}
}

int main()
{
	R = 3;
	N = 4;
	int Matrix[3][4] = {{1, 2, 3, 4},
						{-2, 6, 7, 0},
						{4, 3, 2, 1}};

	int Vector[4] = {1, 0, 2, 1};
	int Res[4];

	MatVecMult(Matrix, Vector, Res);
	for (int i = 0; i < R; i++)
	{
		printf("%i\n", Res[i]);
	}
	return 0;
}