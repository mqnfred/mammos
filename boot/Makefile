include ../Makefile.inc


.PHONY: stage1 stage2


all: stage1 stage2


stage1: bin debug
	make -C stage1
	mv stage1/stage1.bin bin/
	mv stage1/stage1.elf debug/


stage2: bin debug
	make -C stage2
	mv stage2/stage2.bin bin/
	mv stage2/stage2.elf debug/


clean:
	make clean -C stage1
	make clean -C stage2


distclean: clean
	rm -rf bin debug


bin:
	mkdir -p bin


debug:
	mkdir -p debug
