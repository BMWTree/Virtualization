CXX = clang++
CXXFLAGS = -std=c++17 -g

TESTCASE_DIR := tests
TESTCASES = $(wildcard $(TESTCASE_DIR)/*.cpp)
LLFILES = $(patsubst $(TESTCASE_DIR)/%.cpp,$(TESTCASE_DIR)/%.output,$(TESTCASES))

.SECONDARY: $(LLFILES)

run: $(patsubst $(TESTCASE_DIR)/%.cpp,$(TESTCASE_DIR)/%.output,$(TESTCASES))

$(TESTCASE_DIR)/%.output: $(TESTCASE_DIR)/%.exe
	$< $@

$(TESTCASE_DIR)/%.exe: $(TESTCASE_DIR)/%.cpp PerfInfo.o PIFOTree.o SchedStrategy.o
	$(CXX) $(CXXFLAGS) -o $@ $^

PerfInfo.o: PerfInfo.cpp PerfInfo.h
	$(CXX) $(CXXFLAGS) -c $<

SchedStrategy.o: SchedStrategy.cpp SchedStrategy.h
	$(CXX) $(CXXFLAGS) -c $<

PIFOTree.o: PIFOTree.cpp PIFOTree.h PerfInfo.o SchedStrategy.o
	$(CXX) $(CXXFLAGS) -c $<

clean:
	rm *.o *.output tests/*.o tests/*.output
