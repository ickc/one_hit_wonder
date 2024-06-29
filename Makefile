.DEFAULT_GOAL = help

# compile
SRC = $(wildcard \
	src/*.c \
	src/*.cpp \
	src/*.go \
	src/*.hs \
	src/*.js \
	src/*.py \
	src/*.rs \
	src/*.sh \
)
BIN = $(patsubst src/%,bin/%,$(subst .,_,$(SRC)))

# test & benchmark
TXT = $(patsubst bin/%,out/%.txt,$(BIN))
TIME = $(patsubst %.txt, %.time, $(TXT))
CSV = out/bench.csv

PATH1 = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
PATH2 = /run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

.PHONY: all
all:  ## compile, run, diff, and bench
	@$(MAKE) compile run diff
	@$(MAKE) bench -j1

# compile
.PHONY: compile
compile: $(BIN)  ## compile all

# language specific
bin/%_c: src/%.c
	@mkdir -p $(@D)
	gcc -o $@ -O3 -march=armv8.5-a -mtune=native -std=c23 $<
bin/%_cpp: src/%.cpp
	@mkdir -p $(@D)
	g++ -o $@ -O3 -march=armv8.5-a -mtune=native -std=c++23 $<
bin/%_go: src/%.go
	@mkdir -p $(@D)
	go build -o $@ -ldflags="-s -w" -trimpath $<
bin/%_hs: src/%.hs
	@mkdir -p $(@D)
	ghc -o $@ -O2 $<
bin/%_js: src/%.js
	chmod +x $<
	@mkdir -p $(@D)
	ln -f $< $@
bin/%_py: src/%.py
	chmod +x $<
	@mkdir -p $(@D)
	ln -f $< $@
bin/%_rs: src/%.rs
	@mkdir -p $(@D)
	rustc -o $@ -C opt-level=3 -C target-cpu=native --edition=2021 $<
bin/%_sh: src/%.sh
	chmod +x $<
	@mkdir -p $(@D)
	ln -f $< $@

.PHONY: clean_hs clean_compile
clean_hs:  ## clean auxiliary Haskell files
	rm -f src/*.o src/*.hi
clean_compile: clean_hs   ## clean compiled files
	rm -f $(BIN)

# run
.PHONY: run
run: $(TXT)  ## run all
out/%.txt: bin/%
	@mkdir -p $(@D)
	command time -v $< $(PATH1) $(PATH2) > $@ 2> $(@:.txt=.time)

.PHONY: clean_run
clean_run:  ## clean run files
	rm -f $(TXT) $(TIME)

# bench
.PHONY: bench
bench: $(CSV)  ## benchmark all
$(CSV): $(BIN)
	@mkdir -p $(@D)
	hyperfine --shell=none --warmup 1 --export-csv $@ $(foreach bin,$^,'$(bin) $(PATH1) $(PATH2)')

.PHONY: clean_bench
clean_bench:  ## clean benchmark files
	rm -f $(CSV)

# diff
.PHONY: diff
diff: $(TXT)  ## diff all
	for i in $(TXT); do difft out/diffpath_c.txt $$i; done

# format
.PHONY: \
	format_c \
	format_cpp \
	format_hs \
	format_js \
	format_py \
	format_rs \
	format_sh \
	format
format: \
	format_c \
	format_cpp \
	format_hs \
	format_js \
	format_py \
	format_rs \
	format_sh \
	## format all
format_c:  ## format C files
	find src -type f -name '*.c' -exec clang-format -i -style=WebKit {} +
format_cpp:  ## format C++ files
	find src -type f -name '*.cpp' -exec clang-format -i -style=WebKit {} +
format_go:  ## format Go files
	find src -type f -name '*.go' -exec gofmt -w {} +
format_hs:  ## format Haskell files
	find src -type f -name '*.hs' -exec stylish-haskell -i {} +
format_js:  ## format JavaScript files
	find src -type f -name '*.js' -exec prettier --write {} +
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

.PHONY: list_link
list_link:  ## list dynamically linked libraries
	if [[ $$(uname) == Darwin ]]; then \
		find bin -type f -executable -exec otool -L {} +; \
	else \
		find bin -type f -executable -exec readelf --needed-libs {} +; \
	fi

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
