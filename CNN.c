#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {

    // -----------------------------------------------------------



    int N = 3;
    int M = 3;
    int R = 28;
    int C = 28;
    int S = 1;
    int K = 4;

    int Rprime = R * S-K+1;
    int Cprime = C * S-K+1;


    if ((N <= 0) || (M <= 0) || (R <= 0) || (C <= 0) || (S <= 0) || (K <= 0)) {
        printf("ERROR: 0 or negative parameter\n");
        return (1);
    }

    // ------------------------------------------------------------
    // Declare data structures that will reside in off chip memory.
    // Note: if these get too large, you will eventually run out of space
    // on your stack, and this will cause a segmentation fault. A more flexible
    // approach would be to use malloc and store this data on the heap.
    int I[N][R][C];
    int O[M][Rprime][Cprime];
    int B[M];
    int W[M][N][K][K];

    // -----------------------------------------------------------
    // Declare data structures that will reside in BRAM in your hardware
    // design. These will be accessible to your CLP-Lite hardware system
    int Wbuf[K][K];
    int Ibuf[N][R][C];
    int Obuf[Rprime][Cprime];
    int Bbuf;


    // -----------------------------------------------------------
    // As an example, we will generate random inputs, weights, and bias.
    // We will also store these and the parameters to a text file (to
    // make it easy to later verify the correctness of this design)
    FILE *ip, *op, *ip_w, *ip_b;
    ip = fopen("ip.txt", "w");
    ip_w = fopen("ip_w.txt", "w");
    ip_b = fopen("ip_b.txt", "w");
    

    //fprintf(ip, "%d\n%d\n%d\n%d\n%d\n%d\n", N, M, R, C, S, K);

    // Init. RNG
    srand((unsigned int) time(NULL));

	int n, r, c, m, i, j;
	int temp = 0;
    // Generate random test inputs
    for (n = 0; n < N; n++) {
        for (r = 0; r < R; r++) {
            for (c = 0; c < C; c++) {
                I[n][r][c] = temp;
                temp=(rand()%255);
                //printf("%d ", I[n][r][c]);
                fprintf(ip, "%x\n", I[n][r][c]);
            }
        }
    }
	printf("\n");
	temp = 0;
    // Generate random weights
    for (m = 0; m < M; m++)
        for (n = 0; n < N; n++)
            for (i = 0; i < K; i++)
                for (j = 0; j < K; j++) {
                    W[m][n][i][j] = temp;
                    temp++;
                    //printf("%d ", W[m][n][i][j]);
                    fprintf(ip_w,"%x\n", W[m][n][i][j]);
                }
	
	printf("\n");
	temp = 0;
    // Generate random biases
    for (m = 0; m < M; m++) {
        B[m] = temp;
        temp++;
        //printf("%d ", B[m]);
         fprintf(ip_b,"%x\n", B[m]);
    }

	printf("\n");
    fclose(ip);
    fclose(ip_w);
    fclose(ip_b);
    for (r=0; r<Rprime; r++) {
        for (c=0; c<Cprime; c++) {
            for (m=0; m<M; m++) {

                // Copy this output's bias value to bias buffer
                Bbuf = B[m];

                for (n=0; n<N; n++) {
                    for (i=0; i<K; i++) {
                        for (j=0; j<K; j++) {
                            int t1 = W[m][n][i][j] * I[n][r*S+i][c*S+j];

                            // mux: if i==0, j==0, and n==0 we need to add bias.
                            // otherwise, we accumulate
                            int t2 = (i==0 && j==0 && n==0) ? Bbuf : Obuf[r][c];
                            Obuf[r][c]=t1+t2;
                            O[m][r][c] = Obuf[r][c];
                        }
                    }

                }
            }
        }
    }

    // ---------------------------------------------------
    // Store results to text file for easy checking.
    // Write the results to op.txt
    op = fopen("op.txt", "w");
    for (m=0; m<M; m++)
        for (r=0; r<Rprime; r++)
            for (c=0; c<Cprime; c++)
                //printf("%d ", O[m][r][c]);
				fprintf(op,"%4x\n", O[m][r][c]);

	printf("\n");
    //fclose(op);

    return 0;
}
