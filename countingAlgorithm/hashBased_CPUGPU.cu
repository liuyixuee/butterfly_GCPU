#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
#include<bitset>

__global__ 
void hashBasedButterflyCounting_CPUGPU(int *directNB,long long *par_beginPos, int *edgeList, long long edge_num,long long edge_addr,int uCount, int vCount, unsigned long long* globalCount,  int* hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x==0) sharedCount=0;
}