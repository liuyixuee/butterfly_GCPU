#ifndef PARTITIONRECCOUNTING
#define PARTITIONRECCOUNTING

__global__ 
void Intra_Partition_Counting(int *beginPos, int *edgeList, int uCount, int vCount,  int* hashTable, int startId,int vertex_n,int edge_n);
__global__ 
void Inter_Partition_Counting(int *beginPos_i,int *beginPos_j, int *edgeList_i, int *edgeList_j, int uCount, int vCount,  int* hashTable, int startId_i,int startId_j,int vertex_n_i,int vertex_n_j,int edge_n_i,int edge_n_j);
__global__
void test_PairCounting(int v_i,int v_j,int *beginPos, int *edgeList,int startId,int edge_n,int vertex_n,int uCount,int vCount,unsigned int *count);
#endif