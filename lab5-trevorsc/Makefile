SHELL:=/bin/bash

build_multiply_by_adding:
	./findIllegal Multipliers.ms "multiply_by_adding#(4)" 
	mkdir -p buildDir
	msc TBMultiplier.ms MultiplyByAddingTest 
	mv MultiplyByAddingTest buildDir
	mv MultiplyByAddingTest.so buildDir

build_folded_multiplier:
	./findIllegal Multipliers.ms "FoldedMultiplier#(4)"
	mkdir -p buildDir
	msc TBMultiplier.ms FoldedMultiplierTest
	mv FoldedMultiplierTest buildDir
	mv FoldedMultiplierTest.so buildDir

build_fast_folded_multiplier:
	./findIllegal Multipliers.ms "FastFoldedMultiplier#(4)"
	mkdir -p buildDir
	msc TBMultiplier.ms FastFoldedMultiplierTest
	mv FastFoldedMultiplierTest buildDir
	mv FastFoldedMultiplierTest.so buildDir

build_pipeline_math:
	mkdir -p buildDir
	msc TBPipelineMath.ms PipelineMathTest
	mv PipelineMathTest buildDir
	mv PipelineMathTest.so buildDir

build_sorting_network:
	./findIllegal SortingNetworks.ms "BitonicSorter8"
	mkdir -p buildDir
	msc TBSortingNetwork.ms BitonicSorterTest
	mv BitonicSorterTest buildDir
	mv BitonicSorterTest.so buildDir

multiply_by_adding_test: build_multiply_by_adding
	./buildDir/MultiplyByAddingTest

folded_multiplier_test: build_folded_multiplier
	./buildDir/FoldedMultiplierTest

fast_folded_multiplier_test: build_fast_folded_multiplier
	./buildDir/FastFoldedMultiplierTest

pipeline_math_test: build_pipeline_math
	@echo "Running ./buildDir/PipelineMathTest"
	@echo -n "Functionality test: "
	@./buildDir/PipelineMathTest
	@echo "REMINDER: Verify critical-path delay < 500ps using synth!"

sorting_network_test: build_sorting_network
	@echo "Running ./buildDir/BitonicSorterTest"
	@echo -n "Functionality test: "
	@./buildDir/BitonicSorterTest
	@echo "REMINDER: Verify critical-path delay < 250ps using synth!"

all:	build_multiply_by_adding\
	build_folded_multiplier\
	build_fast_folded_multiplier\
	build_pipeline_math\
	build_sorting_network

clean:
	rm -rf buildDir synthDir* *.bo *synth_out

test:
	./test_all.sh

.PHONY: build_multiply_by_adding build_folded_multiplier build_fast_folded_multiplier build_pipeline_math build_sorting_network all clean test
.DEFAULT_GOAL := all
