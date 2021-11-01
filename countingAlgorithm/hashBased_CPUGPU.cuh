#ifndef HASHBASED_CPUGPU
#define HASHBASED_CPUGPU

__global__ 
void hashBasedButterflyCounting_CPUGPU(int *directNB,long long *par_beginPos, int *edgeList, long long edge_num,long long edge_addr,int uCount, int vCount, unsigned long long* globalCount,  int* hashTable, int startVertex, int endVertex);

#endif