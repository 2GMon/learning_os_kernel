run: boot.img
	qemu-system-x86_64 -fda $<

boot.img: boot.nas
	nasm -f bin -o $@ $<

clean: boot.img
	rm $<
