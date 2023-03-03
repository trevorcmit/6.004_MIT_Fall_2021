SHELL:=/bin/bash

fullAdder:
	@./findIllegal ALU.ms fullAdder
	timeout 3m msc Tb.ms Tb_fullAdder

rca32:
	@./findIllegal ALU.ms "rca#(32)"
	timeout 3m msc Tb.ms Tb_rca32

addSub32:
	@./findIllegal ALU.ms "addSub#(32)"
	timeout 3m msc Tb.ms Tb_addSub32
	-@timeout 2m ./check_area 'addSub#(32)' 1.7 'rca#(32)'

cmp:
	@./findIllegal ALU.ms cmp
	timeout 3m msc Tb.ms Tb_cmp

ltu32:
	@./findIllegal ALU.ms ltu32
	timeout 3m msc Tb.ms Tb_ltu32

lt32:
	@./findIllegal ALU.ms lt32
	timeout 3m msc Tb.ms Tb_lt32
	-@timeout 2m ./check_area lt32 1.2 ltu32

sr32:
	@./findIllegal ALU.ms sr32
	timeout 3m msc Tb.ms Tb_sr32
	-@timeout 2m ./check_area sr32 1.2 barrelRShift

sll32:
	@./findIllegal ALU.ms sll32
	timeout 3m msc Tb.ms Tb_sll32
	-@timeout 2m ./check_area sll32 1.2 barrelRShift

sft32:
	@./findIllegal ALU.ms sft32
	timeout 3m msc Tb.ms Tb_sft32
	-@timeout 2m ./check_area sft32 1.9 barrelRShift

alu:
	@./findIllegal ALU.ms alu
	timeout 3m msc Tb.ms Tb_alu
	-@timeout 3m ./check_area alu 1.45 'addSub#(32)' lt32 sft32

fastAdd32:
	@./findIllegal ALU.ms "fastAdd#(32)"
	timeout 3m msc Tb.ms Tb_fastAdd32

all: sr32 sll32 sft32 cmp ltu32 lt32 fullAdder rca32 addSub32 alu fastAdd32

test: all
	./Tb_sr32
	./Tb_sll32
	./Tb_sft32
	./Tb_cmp
	./Tb_ltu32
	./Tb_lt32
	./Tb_fullAdder
	./Tb_rca32
	./Tb_addSub32
	./Tb_alu
	./Tb_fastAdd32
ifneq (,$(wildcard ./Tb_fastAdd32))
	$(eval TEST2=$(shell ./Tb_fastAdd32 | grep -e PASSED))
endif
	@if [ "$(TEST2)" != "" ]; then \
		echo -n "Your delay is: ";\
		synth ALU.ms "fastAdd#(32)" -l multisize | grep -E "Critical-path delay:" | grep -Eo "([0-9]+\.?[0-9]*) ps"; \
		echo; \
	fi
	@[ `wc -c < ./discussion_questions.txt` -gt 100 ] && echo "Lab4.Discussion: PASSED" || echo "Lab4.Discussion: FAILED no content in discussion_questions.txt - put your discussion answers into this file"

clean:
	rm -rf Tb_* *.svg *.bo synthDir checkDir

.PHONY: fullAdder rca32 addSub32 cmp ltu32 lt32 sr32 sll32 sft32 alu fastAdd32 all test clean
.DEFAULT_GOAL := all

