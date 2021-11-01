#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
#include<bitset>

using std::bitset;
using namespace std;

__device__ int* binarySearch_2(int* a, int* b, int x)
{
    while (a<b)
    {
        int* mid=a+((b-a)/2);
        if (*mid<=x) a=mid+1; else b=mid;
    }
    return a;
}

__global__
void test_PairCounting(int v_i,int v_j,int *beginPos, int *edgeList,int startId,int edge_n,int vertex_n,int uCount,int vCount,unsigned int *count)
{

    int v_i_end=beginPos[v_i+1]-1;
    int v_j_end;
    if(v_j==vertex_n-1)
    {
        v_j_end=edge_n-1;
    }
    else
    {
        v_j_end=beginPos[v_j+1]-1;
    }

    int p_i=v_i_end,p_j=v_j_end;
    int large_pop=uCount+vCount;
    while(p_i>=0 &&p_j>=0)
    {
        //w>u and w>v
        if(edgeList[p_i]<=v_i+startId)
        {
            p_i=-1;
            break;
        }
        if(edgeList[p_i]>=edgeList[p_j])
        {
            if(edgeList[p_i]==large_pop) *count+=1;
            //if(edgeList[p_i]==large_pop) printf("large_pop is %d, same with edgelist i,there are %d wedges\n",large_pop,*count);
            large_pop=edgeList[p_i];
            p_i--;
        }
        else{
            if(edgeList[p_j]==large_pop) *count+=1;
            //if(edgeList[p_j]==large_pop) printf("large_pop is %d, same with edgelist j\n",large_pop);
            large_pop=edgeList[p_j];
            p_j--;
        }

    }
    if(p_i==-1 &&edgeList[p_j]==large_pop) *count+=1;
    if(p_j==-1 &&edgeList[p_i]==large_pop) *count+=1;


}
__device__
void PairCounting(int v_i,int v_j,int *beginPos, int *edgeList,int startId,int edge_n,int vertex_n,unsigned int *count,int vertexCount)
{

    int v_i_end=beginPos[v_i+1]-1;
    int v_j_end;
    if(v_j==vertex_n-1)
    {
        v_j_end=edge_n-1;
    }
    else
    {
        v_j_end=beginPos[v_j+1]-1;
    }

    int p_i=v_i_end,p_j=v_j_end;
    int large_pop=vertexCount;
    for(;p_i>=beginPos[v_i]&&p_j>=beginPos[v_j];)
    {
        //w>u and w>v
        if(edgeList[p_i]<=v_i+startId)
        {
            p_i=-1;
            break;
        }
        if(edgeList[p_i]>=edgeList[p_j])
        {
            if(edgeList[p_i]==large_pop) *count+=1;
            //if(edgeList[p_i]==large_pop) printf("large_pop is %d, same with edgelist i,there are %d wedges\n",large_pop,*count);
            large_pop=edgeList[p_i];
            //printf("%d==%d ",large_pop,edgeList[p_i]);
            p_i--;
        }
        else{
            if(edgeList[p_j]==large_pop) *count+=1;
            //if(edgeList[p_j]==large_pop) printf("large_pop is %d, same with edgelist j\n",large_pop);
            large_pop=edgeList[p_j];
            //printf("%d==%d ",large_pop,edgeList[p_j]);
            p_j--;
        }

    }
    if(p_i<beginPos[v_i] &&edgeList[p_j]==large_pop) *count+=1;
    if(p_j<beginPos[v_j] &&edgeList[p_i]==large_pop) *count+=1;
    //printf("wedges between %d and %d is: %d\n",v_i,v_j,*count);
    //printf("\n");
}

__global__
void Intra_Partition_Counting(int *beginPos, int *edgeList, int uCount, int vCount,   int* hashTable, int startId,int vertex_n,int edge_n)
{
    unsigned int count=0;
    int vertexCount=uCount+vCount;
    if(blockIdx.x==0 and threadIdx.x==0)
    {
        printf("In this partition vn=%d and en= %d\n",vertex_n,edge_n);
    }
    for(int v_i=0+blockIdx.x;v_i<vertex_n;v_i+=gridDim.x)//a block for a v_i
    {
        for(int v_j=v_i+1+threadIdx.x;v_j<vertex_n;v_j+=blockDim.x)
        {
            PairCounting(v_i,v_j,beginPos,edgeList,startId,edge_n,vertex_n,&count,vertexCount);
            hashTable[v_i*vertex_n+v_j]=count;
            count=0;
        }
        
        
    }
    __syncthreads();
}


__device__
void Inter_PairCounting(int v_i,int v_j,int *beginPos_i,int *beginPos_j,int *edgeList_i,int *edgeList_j,int startId_i,int startId_j,int edge_n_i,int edge_n_j,int vertex_n_i,int vertex_n_j,int uCount,int vCount, unsigned int *count)
{
    
    int v_i_end=v_i==vertex_n_i-1?edge_n_i-1:beginPos_i[v_i+1]-1;//last one differently
    int v_j_end=v_j==vertex_n_j-1?edge_n_j-1:beginPos_j[v_j+1]-1;

    int p_i=v_i_end,p_j=v_j_end;
    int large_pop=uCount+vCount;
    for(;p_i>=beginPos_i[v_i]&&p_j>=beginPos_j[v_j];)
    {
        //w>u and w>v
        if(edgeList_i[p_i]<=v_i+startId_i)
        {
            p_i=-1;
            break;
        }
        if(edgeList_i[p_i]>=edgeList_j[p_j])
        {
            if(edgeList_i[p_i]==large_pop) *count+=1;
            large_pop=edgeList_i[p_i];
            p_i--;
        }
        else{
            if(edgeList_j[p_j]==large_pop) *count+=1;
            large_pop=edgeList_j[p_j];
            p_j--;
        }

    }
    if(p_i<beginPos_i[v_i] &&edgeList_j[p_j]==large_pop) *count+=1;
    if(p_j<beginPos_j[v_j] &&edgeList_i[p_i]==large_pop) *count+=1;
}

__global__ 
void Inter_Partition_Counting(int *beginPos_i,int *beginPos_j, int *edgeList_i, int *edgeList_j, int uCount, int vCount,  int* hashTable, int startId_i,int startId_j,int vertex_n_i,int vertex_n_j,int edge_n_i,int edge_n_j)
{
    unsigned int count=0;
    if(blockIdx.x==0 && threadIdx.x==0)
    {
        printf("In this inter partitions vn_i=%d and en_i= %d   vn_j=%d and en_j= %d\n",vertex_n_i,edge_n_i,vertex_n_j,edge_n_j);
    }
    for(int v_i=0+blockIdx.x;v_i<vertex_n_i;v_i+=gridDim.x)//a block for a v_i
    {
        for(int v_j=0+threadIdx.x;v_j<vertex_n_j;v_j+=blockDim.x)
        {
            
            if(v_j+startId_j>v_i+startId_i) 
            {
                Inter_PairCounting(v_i,v_j,beginPos_i,beginPos_j,edgeList_i,edgeList_j,startId_i,startId_j,edge_n_i,edge_n_j,vertex_n_i,vertex_n_j,uCount,vCount,&count);
                
            }
            else
            {
                Inter_PairCounting(v_j,v_i,beginPos_j,beginPos_i,edgeList_j,edgeList_i,startId_j,startId_i,edge_n_j,edge_n_i,vertex_n_j,vertex_n_i,uCount,vCount,&count);
                
            }
            hashTable[v_i*vertex_n_j+v_j]=count;
            
            count=0;
            
        }
    }
    
    __syncthreads();
}