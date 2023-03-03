SHELL:=/bin/bash

build_HelperTest:
	mkdir -p buildDir
	timeout 2m  msc HelperTest.ms HelperTest 
	mv HelperTest buildDir
	mv HelperTest.so buildDir

build_DirectMappedMicrotest:
	mkdir -p buildDir
	timeout 2m  msc DirectMappedCacheTB.ms DirectMappedMicrotestAutograde
	mv DirectMappedMicrotestAutograde buildDir
	mv DirectMappedMicrotestAutograde.so buildDir

build_TwoWayMicrotest:
	mkdir -p buildDir
	timeout 2m  msc TwoWayCacheTB.ms TwoWayMicrotestAutograde
	mv TwoWayMicrotestAutograde buildDir
	mv TwoWayMicrotestAutograde.so buildDir

build_DirectMappedBeveren:
	mkdir -p buildDir
	timeout 2m  msc DirectMappedCacheTB.ms DirectMappedBeverenAutograde
	mv DirectMappedBeverenAutograde buildDir
	mv DirectMappedBeverenAutograde.so buildDir

build_TwoWayBeveren:
	mkdir -p buildDir
	timeout 2m  msc TwoWayCacheTB.ms TwoWayBeverenAutograde
	mv TwoWayBeverenAutograde buildDir
	mv TwoWayBeverenAutograde.so buildDir

HelperTest:
	ms sim HelperTest.ms HelperTest 

DirectMappedMicrotest:
	ms sim DirectMappedCacheTB.ms DirectMappedMicrotest

TwoWayMicrotest:
	ms sim TwoWayCacheTB.ms TwoWayMicrotest

DirectMappedBeveren:
	ms sim DirectMappedCacheTB.ms DirectMappedBeverenTest

TwoWayBeveren:
	ms sim TwoWayCacheTB.ms TwoWayBeverenTest


clean:
	rm -rf buildDir *.so *.bo

all:	build_HelperTest \
	build_DirectMappedMicrotest \
	build_TwoWayMicrotest \
	build_DirectMappedBeveren \
	build_TwoWayBeveren

test: all
	./test_all.sh

.PHONY: clean all test HelperTest DirectMappedMicrotest TwoWayMicrotest DirectMappedBeveren TwoWayBeveren

.DEFAULT_GOAL := all
