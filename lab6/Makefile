SHELL:=/bin/bash

.PHONY: all clean superclean Processor decode_test execute_test

all: Processor DecodeTB ExecuteTB

Processor: Processor.ms Decode.ms Execute.ms ALU.ms
	msc $< $@

DecodeTB: DecodeTB.ms Decode.ms
	msc DecodeTB.ms DecodeTB

decode_test: DecodeTB
	./DecodeTB

ExecuteTB: ExecuteTB.ms Execute.ms ALU.ms
	msc ExecuteTB.ms ExecuteTB

execute_test: ExecuteTB
	./ExecuteTB

clean:
	rm -rf *.v *.bo *.ba *.cxx *.o *.h *.so mem.vmh
	rm -rf test_out
	rm -rf Processor DecodeTB ExecuteTB

superclean: clean
	make -C sw clean

test: all
	./test_all.sh

