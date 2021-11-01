#ifndef GRAPH_H
#define GRAPH_H
#include <string>

using namespace std;
class graph
{
    public:
    long long* beginPos,*par_beginPos;
    int* edgeList,*par_edgeList;
    int uCount,vCount,breakVertex32,breakVertex10,vertexCount;
    long long edgeCount;
    void loadgraph_test(string folderName,int bound);
    void loadgraph(string folderName,int bound);
    void loadWangkaiGraph(string folderName,int bound);
    ~graph();
};

#endif