exe=par_butterfly.bin
N=1
cucc= "$(shell which nvcc)"
cc= "$(shell which g++)"
commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64  -g -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter
cuflags= -g -G --compiler-options -Wall --gpu-architecture=compute_80 --gpu-code=sm_80 -m64 -c -O3    # --resource-usage 

.SILENT: cucc
.SILENT: cc
.SILENT: cuflags
.SILENT: %.o


objs	= 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu) $(wildcard *.cu)) \
			$(patsubst %.cpp,%.o,$(wildcard *.cpp)) 
			


deps	= 	$(wildcard ./*.cuh) \
			$(wildcard ./*.hpp) \
			$(wildcard ./*.h) \
			$(wildcard countingAlgorithm/*.cuh) \
			$(wildcard countingAlgorithm/*.hpp) \
			$(wildcard countingAlgorithm/*.h) 

# foldobjs = 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu)) 



%.o:%.cu 
	$(cucc) -c $(cuflags) $<  -o $@ 

%.o:%.cpp 
	$(cc) -c  $(commflags) $< -o $@ 

$(exe):$(objs)
	$(cc) $(objs) $(commflags) -o $(exe)
# rm -rf *.o 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0

clean:
	rm -rf *.o countingAlgorithm/*.o $(exe)

test:
	./par_butterfly.bin /home/lyx/datasets/bipartite/condmat/sorted/ 1


# 	./butterfly.bin ../dataset/edit-suwikibooks/ 1
#edit-enwikiversity
#edit-ltwiki
#wiki-it/sorted/

#amazon/
#livejournal
#	./butterfly.bin ../dataset/bipartite/wiki-it/sorted/ 1