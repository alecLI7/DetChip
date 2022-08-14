RISCV32i='/opt/riscv32i/'
echo '$RISCV32i = '$RISCV32i

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./timer_mg.o ../timer_mg/timer_mg.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./pkt_io.o ../pkt_io/pkt_io.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./ptp_riscv.o ../ptp_riscv/ptp_riscv.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./task.o ./task.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./irq.o ./irq.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -O0 --std=c99  -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wwrite-strings -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -Wno-address-of-packed-member -pedantic -ffreestanding -nostdlib -o ./tuman_program.o ./tuman_program.c

$RISCV32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -o ./start.o ./start.S

$RISCV32i/bin/riscv32-unknown-elf-gcc -O0 -ffreestanding -nostdlib -o ./firmware.elf -Wl,-Bstatic,-T,./sections.lds,-Map,./firmware.map,--strip-debug ./start.o ./timer_mg.o ./pkt_io.o ./ptp_riscv.o ./tuman_program.o ./irq.o ./task.o -lgcc

chmod -x ./firmware.elf

$RISCV32i/bin/riscv32-unknown-elf-objdump -S ./firmware.elf > ./firmware.dis
$RISCV32i/bin/riscv32-unknown-elf-objcopy -O binary ./firmware.elf ./firmware.bin
chmod -x ./firmware.bin

python3 ./makehex.py ./firmware.bin 16384 > ./firmware.hex

# python3 ./cut.py

echo "Done !"

rm *.o
