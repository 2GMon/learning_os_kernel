.SUFFIXES: .nas .o

.nas.o:
	nasm $< -f bin -o $@

run: kernel.img
	qemu-system-x86_64 -fda $<

kernel.img: boot_5_user_tasks.o kernel_5_user_tasks.o
	cat $^ > $@

clean:
	rm *.img *.o
