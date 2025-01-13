#!/bin/bash -x

libdir=../../sifive-libc
vardir=../../whole-memcpys

HASH1="6528013b5f5ba6bb3934b7f5fe57a3110680530f"
HASH2="db95037b428e28b084ce550872406da9ba4217bf"

#cp ${vardir}/memcpy_vext-nf1-re8.S ${libdir}/src/memcpy_vext.S
#./run_all_benchmarks.py --qemulist ${HASH1} ${HASH2} --bmlist memcpy --resdir results_$(date '+%F_%H-%M-%S')_nf1_re8

for i in 1 2 4 8; do
	for j in 8 16 32 64; do
#		if [ $i -eq 1 ] && [ $j -eq 8 ]; then
#			continue
#		fi
		cp ${vardir}/memcpy_vext-nf${i}-re${j}.S ${libdir}/src/memcpy_vext.S
		./run_all_benchmarks.py --qemulist ${HASH1} ${HASH2} --bmlist memcpy --resdir results_$(date '+%F_%H_%M_%S')_nf${i}_re${j}
	done
done

echo
echo "All Done!"
