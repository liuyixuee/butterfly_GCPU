#include <iostream>
#include "graph.h"
#include "wtime.h"
#include "util.h"
#include <cub/cub.cuh>
#include <fstream>
#include<vector>
#include <cub/util_type.cuh>
#include "countingAlgorithm/partitionRecCounting.cuh"

#define blocknumber 128
#define blocksize 1024
#define hash_blocksize 1024
using namespace std;

int FR(graph* G,int bound )
{
    cudaSetDeviceFlags (cudaDeviceMapHost);//启用zerocopy
    
    long long vertexCount=G->uCount+G->vCount;
    int *hashTable;
    
    float *time;
    unsigned long long butterfly_num=0;
    vector<int> par_vertex_id;//each partition.i start from par_vertex_id[i]


    //partition
    int par_id=0;
    long long par_sum=0;
    par_vertex_id.push_back(0);
    if(vertexCount>1)
    {
        par_sum=G->beginPos[1]-G->beginPos[0];
    }
    else{
        cout<<"ERROR: less than one vertex"<<endl;
    }
    
    for(int vertex=1;vertex<G->uCount+G->vCount;vertex++)
    {
        long long deg=G->beginPos[vertex+1]-G->beginPos[vertex];
        if(par_sum+deg+1>bound)//是否考虑deg>bound
        {
            par_vertex_id.push_back(vertex);
            cout<<"push back vertex "<<vertex<<endl;
            par_sum=deg+1;
        } 
        else
        {
            par_sum+=(deg+1);
        }
    }
    par_vertex_id.push_back(G->uCount+G->vCount);
    long long largest_par=0;
    for(int i=0;i<par_vertex_id.size()-1;i++)
    {
        if(par_vertex_id[i+1]-par_vertex_id[i]>largest_par) largest_par=par_vertex_id[i+1]-par_vertex_id[i];
    }
    cudaHostAlloc((void**) &hashTable, largest_par*largest_par*sizeof(int),
         cudaHostAllocWriteCombined | cudaHostAllocMapped);
     memset(hashTable, 0, largest_par*largest_par*sizeof(int));
     
     int *D_hashTable;
     cudaHostGetDevicePointer(&D_hashTable, hashTable, 0);
    
    //intra_partition
    //Memory Allocating and Data transferring
    

    for(int par_id=0;par_id<par_vertex_id.size()-1;par_id++)
    {
        //definition
        
        int* D_beginPos,*H_beginPos;
        int* D_edgeList;
        int vertex_n=par_vertex_id[par_id+1]-par_vertex_id[par_id];
        int edge_n=G->beginPos[par_vertex_id[par_id+1]]-G->beginPos[par_vertex_id[par_id]];
        //memory allocation
        HRR(cudaMalloc(&D_beginPos,sizeof(int)*vertex_n));
        HRR(cudaMalloc(&D_edgeList,sizeof(int)*edge_n));
        H_beginPos=new int[vertex_n];
        //initial H_beginPos long long ->int
        for(int v=par_vertex_id[par_id];v<par_vertex_id[par_id+1];v++)
        {
            H_beginPos[v-par_vertex_id[par_id]]=G->beginPos[v]-G->beginPos[par_vertex_id[par_id]];
        }
        
        HRR(cudaMemcpy(D_beginPos,H_beginPos,sizeof(int)*vertex_n,cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(D_edgeList,G->edgeList+G->beginPos[par_vertex_id[par_id]],sizeof(int)*edge_n,cudaMemcpyHostToDevice));
        Intra_Partition_Counting<<<blocknumber,hash_blocksize>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,D_hashTable,par_vertex_id[par_id],vertex_n,edge_n);
        HRR(cudaDeviceSynchronize());
        HRR(cudaFree(D_beginPos));
        HRR(cudaFree(D_edgeList));
        for(int i=0;i<vertex_n*vertex_n;i++)
        {
            int ht=hashTable[i];
            butterfly_num+=(ht*(ht-1)/2);
        }
        memset(hashTable, 0, largest_par*largest_par*sizeof(int));
        
    }
    cout<<"intrra butterfly num="<<butterfly_num<<endl;
    //inter_partition
    for(int par_i=0;par_i<par_vertex_id.size()-1;par_i++)
    {
        for(int par_j=par_i+1;par_j<par_vertex_id.size()-1;par_j++)
        {
            printf("iiiii");
            int *beginPos_i,*beginPos_j,*H_beginPos_i,*H_beginPos_j;
            int *edgeList_i,*edgeList_j;
            int vertex_n_i=par_vertex_id[par_i+1]-par_vertex_id[par_i];
            int vertex_n_j=par_vertex_id[par_j+1]-par_vertex_id[par_j];
            int edge_n_i=G->beginPos[par_vertex_id[par_i+1]]-G->beginPos[par_vertex_id[par_i]];
            int edge_n_j=G->beginPos[par_vertex_id[par_j+1]]-G->beginPos[par_vertex_id[par_j]];
            HRR(cudaMalloc(&beginPos_i,sizeof(int)*vertex_n_i));
            HRR(cudaMalloc(&beginPos_j,sizeof(int)*vertex_n_j));
            HRR(cudaMalloc(&edgeList_i,sizeof(int)*edge_n_i));
            HRR(cudaMalloc(&edgeList_j,sizeof(int)*edge_n_j));
            H_beginPos_i=new int[vertex_n_i];
            H_beginPos_j=new int[vertex_n_j];
            for(int v=par_vertex_id[par_i];v<par_vertex_id[par_i+1];v++)
            {
                H_beginPos_i[v-par_vertex_id[par_i]]=G->beginPos[v]-G->beginPos[par_vertex_id[par_i]];
            }
            for(int v=par_vertex_id[par_j];v<par_vertex_id[par_j+1];v++)
            {
                H_beginPos_j[v-par_vertex_id[par_i]]=G->beginPos[v]-G->beginPos[par_vertex_id[par_j]];
            }
            HRR(cudaMemcpy(beginPos_i,H_beginPos_i,sizeof(int)*vertex_n_i,cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(edgeList_i,G->edgeList+G->beginPos[par_vertex_id[par_i]],sizeof(int)*edge_n_i,cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(beginPos_j,H_beginPos_j,sizeof(int)*vertex_n_j,cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(edgeList_j,G->edgeList+G->beginPos[par_vertex_id[par_j]],sizeof(int)*edge_n_j,cudaMemcpyHostToDevice));
            printf("222");
            Inter_Partition_Counting<<<blocknumber,hash_blocksize>>>(beginPos_i,beginPos_j,edgeList_i,edgeList_j,G->uCount,G->vCount,D_hashTable,par_vertex_id[par_i],par_vertex_id[par_j],vertex_n_i,vertex_n_j,edge_n_i,edge_n_j);
            HRR(cudaDeviceSynchronize());
            HRR(cudaFree(beginPos_i));
            HRR(cudaFree(edgeList_i));
            HRR(cudaFree(beginPos_j));
            HRR(cudaFree(edgeList_j));
            for(int i=0;i<vertex_n_i*vertex_n_j;i++)
            {
                int ht=hashTable[i];
                butterfly_num+=(ht*(ht-1)/2);
            }
            memset(hashTable, 0, largest_par*largest_par*sizeof(int));
        }
    }
    
    // for(long long i=0;i<vertexCount*vertexCount;i++)
    // {
    //     int ht=hashTable[i];
    //     butterfly_num+=(ht*(ht-1)/2);
    // }
    cout<<"total butterfly num="<<butterfly_num<<endl;
    cudaFreeHost(hashTable);
    return 0;
}