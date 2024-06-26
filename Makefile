.DEFAULT_GOAL = help

# compile
SRC_C = $(wildcard src/*.c)
BIN_C = $(patsubst src/%.c, bin/%_c, $(SRC_C))
CC = gcc
ARG_C = -O3 -march=armv8.5-a -mtune=native -std=c23
# test & benchmark
PATH1 = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
PATH2 = ~/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

# compile
.PHONY: compile compile_c
compile: compile_c  ## compile all
compile_c: $(BIN_C)  ## compile c

bin/%_c: src/%.c
	@mkdir -p $(@D)
	$(CC) -o $@ $< $(ARG_C)

.PHONY: clean_compile
clean_compile:  ## clean compiled files
	rm -rf bin

# run
.PHONY: run run_py run_sh run_c
run: run_py run_sh run_c  ## run all
run_py: out/py.txt  ## run python version
out/py.txt: src/diffpath.py
run_sh: out/sh.txt  ## run shell version
out/sh.txt: src/diffpath.sh
run_c: out/c.txt  ## run c version
out/c.txt: bin/diffpath_c

out/py.txt out/sh.txt out/c.txt: 
	@mkdir -p $(@D)
	$< $(PATH1) $(PATH2) > $@

.PHONY: clean_run
clean_run:  ## clean run files
	rm -rf out/

# bench
.PHONY: bench bench_py bench_sh bench_c
bench: bench_py bench_sh bench_c  ## benchmark all
bench_py: out/py.hyperfine  ## benchmark python version
out/py.hyperfine: src/diffpath.py
bench_sh: out/sh.hyperfine  ## benchmark shell version
out/sh.hyperfine: src/diffpath.sh
bench_c: out/c.hyperfine  ## benchmark c version
out/c.hyperfine: bin/diffpath_c

out/py.hyperfine out/sh.hyperfine out/c.hyperfine:
	@mkdir -p $(@D)
	hyperfine --warmup 1 '$< $(PATH1) $(PATH2)' | tee $@

.PHONY: clean_bench
clean_bench:  ## clean benchmark files
	rm -rf bench/

# diff
.PHONY: diff
diff:  ## diff all
	difft out/py.txt out/sh.txt
	difft out/py.txt out/c.txt
	difft out/sh.txt out/c.txt

.PHONY: clean
clean: clean_compile clean_run clean_bench  ## clean all

.PHONY: help
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
print-%:
	$(info $* = $($*))
