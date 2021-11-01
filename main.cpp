#include <iostream>
#include "graph.h"
#include "fast_rectangle.h"
#include <string>
#include <cstdlib>
#include <cstdio>

using namespace std;

void printGraph(graph *bipartiteGraph)
{
    for (int i=0;i<bipartiteGraph->uCount+bipartiteGraph->vCount+1;i++)
        cout<<bipartiteGraph->beginPos[i]<<' ';
    cout<<endl;
    for (int i=0;i<bipartiteGraph->edgeCount;i++)
        cout<<bipartiteGraph->edgeList[i]<<' ';
    cout<<endl;
}
// int* binarySearchs(int* a, int* b, int x)
// {
//     while (a<b)
//     {
//         int* mid=a+((b-a)/2);
//         if (*mid<=x) a=mid+1; else b=mid;
//     }
//     return a;
// }
int main(int argc, char* argv[])
{
    // int a[3]={16055,71899,99412};
    // printf("%d %d 66\n",a,binarySearchs(a,a+3,71899));
    // sort_test();
    // return 0;
    string path;
    if (argc>1)
    {
        path=argv[1];
    }
    int p=0;
    if (argc>1)
    {
        p=atoi(argv[2]);
    }
    int bound=100000;
    graph *bipartiteGraph=new graph;
    if (p)
    {
        bipartiteGraph->loadgraph(path,bound);
    }
    else
    {
        bipartiteGraph->loadWangkaiGraph(path,bound);
    }
    FR(bipartiteGraph,bound);
    //test();
    delete(bipartiteGraph);
    return 0;
}