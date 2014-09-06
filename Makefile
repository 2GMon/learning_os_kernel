.SUFFIXES: .nas .o

.nas.o:
	nasm $< -f bin -o $@

run: kernel.img
	qemu-system-x86_64 -fda $<

kernel.img: boot.o kernel.o
	cat $^ > $@

clean:
	rm *.img *.o
