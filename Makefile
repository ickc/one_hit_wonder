.DEFAULT_GOAL = help

# compile
SRC_C = $(wildcard src/*.c)
SRC_CPP = $(wildcard src/*.cpp)
SRC_HS = $(wildcard src/*.hs)
SRC_PY = $(wildcard src/*.py)
SRC_RS = $(wildcard src/*.rs)
SRC_SH = $(wildcard src/*.sh)
SRC = $(SRC_C) $(SRC_CPP) $(SRC_HS) $(SRC_PY) $(SRC_RS) $(SRC_SH)
BIN_C = $(patsubst src/%.c, bin/%_c, $(SRC_C))
BIN_CPP = $(patsubst src/%.cpp, bin/%_cpp, $(SRC_CPP))
BIN_HS = $(patsubst src/%.hs, bin/%_hs, $(SRC_HS))
BIN_PY = $(patsubst src/%.py, bin/%_py, $(SRC_PY))
BIN_RS = $(patsubst src/%.rs, bin/%_rs, $(SRC_RS))
BIN_SH = $(patsubst src/%.sh, bin/%_sh, $(SRC_SH))
BIN = $(BIN_C) $(BIN_CPP) $(BIN_HS) $(BIN_PY) $(BIN_RS) $(BIN_SH)

# C
CC = gcc
ARG_C = -O3 -march=armv8.5-a -mtune=native -std=c23
# CXX
CXX = g++
ARG_CPP = -O3 -march=armv8.5-a -mtune=native -std=c++23
# HS
ARG_HS = -O2
# RS
ARGS_RS = -C opt-level=3 -C target-cpu=native --edition=2021

# test & benchmark
TXT_C = $(patsubst src/%.c, out/c.txt, $(SRC_C))
TXT_CPP = $(patsubst src/%.cpp, out/cpp.txt, $(SRC_CPP))
TXT_HS = $(patsubst src/%.hs, out/hs.txt, $(SRC_HS))
TXT_PY = $(patsubst src/%.py, out/py.txt, $(SRC_PY))
TXT_RS = $(patsubst src/%.rs, out/rs.txt, $(SRC_RS))
TXT_SH = $(patsubst src/%.sh, out/sh.txt, $(SRC_SH))
TXT = $(TXT_C) $(TXT_CPP) $(TXT_HS) $(TXT_PY) $(TXT_RS) $(TXT_SH)
TIME = $(patsubst %.txt, %.time, $(TXT))
BENCH_C = $(patsubst src/%.c, out/c.hyperfine, $(SRC_C))
BENCH_CPP = $(patsubst src/%.cpp, out/cpp.hyperfine, $(SRC_CPP))
BENCH_HS = $(patsubst src/%.hs, out/hs.hyperfine, $(SRC_HS))
BENCH_PY = $(patsubst src/%.py, out/py.hyperfine, $(SRC_PY))
BENCH_RS = $(patsubst src/%.rs, out/rs.hyperfine, $(SRC_RS))
BENCH_SH = $(patsubst src/%.sh, out/sh.hyperfine, $(SRC_SH))
BENCH = $(BENCH_C) $(BENCH_CPP) $(BENCH_HS) $(BENCH_PY) $(BENCH_RS) $(BENCH_SH)

PATH1 = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
PATH2 = /run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

.PHONY: all
all:  ## compile, run, diff, and bench
	@$(MAKE) compile run diff
	@$(MAKE) bench -j1

# compile
.PHONY: compile
compile: $(BIN)  ## compile all

# C
bin/%_c: src/%.c
	@mkdir -p $(@D)
	$(CC) $< -o $@ $(ARG_C)
bin/%_cpp: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $< -o $@ $(ARG_CPP)
bin/%_hs: src/%.hs
	@mkdir -p $(@D)
	ghc $< -o $@ $(ARG_HS)
bin/%_py: src/%.py
	@mkdir -p $(@D)
	ln -sf ../$< $@
bin/%_rs: src/%.rs
	@mkdir -p $(@D)
	rustc $< -o $@ $(ARGS_RS)
bin/%_sh: src/%.sh
	@mkdir -p $(@D)
	ln -sf ../$< $@

.PHONY: clean_compile
clean_compile:  ## clean compiled files
	rm -f $(BIN)

# run
.PHONY: run
run: $(TXT)  ## run all
out/%.txt: bin/diffpath_%
	@mkdir -p $(@D)
	command time -v $< $(PATH1) $(PATH2) > $@ 2> $(@:.txt=.time)

.PHONY: clean_run
clean_run:  ## clean run files
	rm -f $(TXT) $(TIME)

# bench
.PHONY: bench
bench: $(BENCH)  ## benchmark all
out/%.hyperfine: bin/diffpath_%
	@mkdir -p $(@D)
	hyperfine --warmup 1 '$< $(PATH1) $(PATH2)' | tee $@

.PHONY: clean_bench
clean_bench:  ## clean benchmark files
	rm -f $(BENCH)

# diff
.PHONY: diff
diff: $(TXT)  ## diff all
	difft out/c.txt out/cpp.txt
	difft out/c.txt out/hs.txt
	difft out/c.txt out/py.txt
	difft out/c.txt out/rs.txt
	difft out/c.txt out/sh.txt

# format
.PHONY: format \
	format_c \
	format_cpp \
	format_hs \
	format_py \
	format_rs \
	format_sh
format: \
	format_c \
	format_cpp \
	format_hs \
	format_py \
	format_rs \
	format_sh \
	## format all
format_c:  ## format C files
	find src -type f -name '*.c' -exec clang-format -i -style=WebKit {} +
format_cpp:  ## format C++ files
	find src -type f -name '*.cpp' -exec clang-format -i -style=WebKit {} +
format_hs:  ## format Haskell files
	find src -type f -name '*.hs' -exec stylish-haskell -i {} +
format_py:  ## format Python files
	autoflake --in-place --recursive --expand-star-imports --remove-all-unused-imports --ignore-init-module-imports --remove-duplicate-keys --remove-unused-variables src
	black src
	isort src
format_rs:  ## format Rust files
	find src -type f -name '*.rs' -exec rustfmt {} +
format_sh:  ## format Shell files
	find src -type f -name '*.sh' \
	-exec sed -i -E \
		-e 's/\$$([a-zA-Z_][a-zA-Z0-9_]*)/$${\1}/g' \
		-e 's/([^[])\[ ([^]]+) \]/\1[[ \2 ]]/g' \
		{} + \
	-exec shfmt \
		--write \
		--simplify \
		--indent 4 \
		--case-indent \
		--space-redirects \
		{} +

.PHONY: clean
clean: \
	clean_compile \
	clean_run \
	clean_bench \
	## clean all
	rm -rf bin out

.PHONY: help
# modified from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@sed ':a;N;$$!ba;s/\\\n//g' $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
print-%:
	$(info $* = $($*))
