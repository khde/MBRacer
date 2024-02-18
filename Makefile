AS = nasm
ASFLAGS = -f bin

SRC = src/mbracer.asm
DST = mbracer.img

$(DST): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(DST)

run: $(DST)
	qemu-system-i386 -fda $(DST)
