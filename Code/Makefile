OBJS = example.o graphTMCM.o graph.o maxflow.o readConfigFile.o
CC = g++ 
DEBUG = -g
WARN = -Wall
CFLAGS += -c -std=c++0x $(DEBUG) $(WARN)
LFLAGS += -std=c++0x $(DEBUG) $(WARN)

example : $(OBJS)
	$(CC) -o example $(LFLAGS) $(OBJS) 

example.o: example.cpp graph.cpp graphTMCM.cpp readConfigFile.cpp
	$(CC) $(CFLAGS) example.cpp

graphTMCM.o: graphTMCM.cpp graph.h readConfigFile.h 
	$(CC) $(CFLAGS) graphTMCM.cpp

graph.o: graph.cpp graph.h block.h
	$(CC) $(CFLAGS) graph.cpp

maxflow.o: maxflow.cpp graph.h
	$(CC) $(CFLAGS) maxflow.cpp

readConfigFile.o: readConfigFile.cpp
	$(CC) $(CFLAGS) readConfigFile.cpp

clean:
	rm -f $(OBJS) core *.stackdump *.bak
