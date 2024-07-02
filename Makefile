.DEFAULT_GOAL = help
.PHONY: all
all: compile run test  ## compile, run, and test

# compile ######################################################################

EXT =

define symlink
	chmod +x $<
	@mkdir -p $(@D)
	ln -f $< $@
endef

# C
EXT += c
SRC_c = $(wildcard src/*.c)
BIN_c = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_c)))
bin/%_c: src/%.c
	@mkdir -p $(@D)
	gcc -o $@ -O3 -march=armv8.5-a -mtune=native -std=c23 $<
.PHONY: clean_c format_c
clean_c:  ## clean C binaries
	rm -f $(BIN_c)
format_c:  ## format C files
	find src -type f -name '*.c' -exec clang-format -i -style=WebKit {} +

# C++
EXT += cpp
SRC_cpp = $(wildcard src/*.cpp)
BIN_cpp = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_cpp)))
bin/%_cpp: src/%.cpp
	@mkdir -p $(@D)
	g++ -o $@ -O3 -march=armv8.5-a -mtune=native -std=c++23 $<
.PHONY: clean_cpp format_cpp
clean_cpp:  ## clean C++ binaries
	rm -f $(BIN_cpp)
format_cpp:  ## format C++ files
	find src -type f -name '*.cpp' -exec clang-format -i -style=WebKit {} +

# Go
EXT += go
SRC_go = $(wildcard src/*.go)
BIN_go = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_go)))
bin/%_go: src/%.go
	@mkdir -p $(@D)
	go build -o $@ -ldflags="-s -w" -trimpath $<
.PHONY: clean_go format_go
clean_go:  ## clean Go binaries
	rm -f $(BIN_go)
format_go:  ## format Go files
	find src -type f -name '*.go' -exec gofmt -w {} +

# Haskell
EXT += hs
SRC_hs = $(wildcard src/*.hs)
BIN_hs = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_hs)))
bin/%_hs: src/%.hs
	@mkdir -p $(@D)
	ghc -o $@ -O2 $<
.PHONY: clean_hs format_hs
clean_hs:  ## clean Haskell files
	rm -f $(BIN_hs) src/*.o src/*.hi
format_hs:  ## format Haskell files
	find src -type f -name '*.hs' -exec stylish-haskell -i {} +

# Lua
EXT += lua
SRC_lua = $(wildcard src/*.lua)
BIN_lua = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_lua)))
# this depends on 3rd party: `luarocks install luafilesystem --local`
bin/%_lua: src/%.lua
	$(symlink)
.PHONY: clean_lua format_lua
clean_lua:  ## clean Lua binaries
	rm -f $(BIN_lua)
format_lua:  ## format Lua files
	find src -type f -name '*.lua' -exec stylua --indent-type Spaces {} +

# Python
EXT += py
SRC_py = $(wildcard src/*.py)
BIN_py = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_py)))
bin/%_py: src/%.py
	$(symlink)
.PHONY: clean_py format_py
clean_py:  ## clean Python binaries
	rm -f $(BIN_py)
format_py:  ## format Python files
	autoflake --in-place --recursive --expand-star-imports --remove-all-unused-imports --ignore-init-module-imports --remove-duplicate-keys --remove-unused-variables src
	black src
	isort src

# Rust
EXT += rs
SRC_rs = $(wildcard src/*.rs)
BIN_rs = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_rs)))
bin/%_rs: src/%.rs
	@mkdir -p $(@D)
	rustc -o $@ -C opt-level=3 -C target-cpu=native --edition=2021 $<
.PHONY: clean_rs format_rs
clean_rs:  ## clean Rust binaries
	rm -f $(BIN_rs)
format_rs:  ## format Rust files
	find src -type f -name '*.rs' -exec rustfmt {} +

# bash
EXT += sh
SRC_sh = $(wildcard src/*.sh)
BIN_sh = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_sh)))
bin/%_sh: src/%.sh
	$(symlink)
.PHONY: clean_sh format_sh
clean_sh:  ## clean Shell binaries
	rm -f $(BIN_sh)
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

# TypeScript
EXT += ts
SRC_ts = $(wildcard src/*.ts)
BIN_ts = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_ts)))
bin/%_ts: src/%.ts node_modules/
	@mkdir -p $(@D)
	tsc $< --outDir $(@D) --target esnext --module nodenext --strict --types node --removeComments
	mv bin/$*.js $@
	chmod +x $@
node_modules/:
	npm install @types/node --no-save
.PHONY: clean_ts format_ts
clean_ts:  ## clean auxiliary TypeScript files
	rm -f $(BIN_ts)
	rm -rf node_modules
format_ts:  ## format TypeScript files
	find src -type f -name '*.ts' -exec prettier --write {} +

# all

BIN = $(foreach ext,$(EXT),$(BIN_$(ext)))
.PHONY: compile
compile: $(BIN)  ## compile all

.PHONY: clean_compile
clean_compile: $(foreach ext,$(EXT),clean_$(ext))  ## clean compiled files

.PHONY: format
format: $(foreach ext,$(EXT),format_$(ext))  ## format all

# run & benchmark #############################################################

TXT = $(patsubst bin/%,out/%.txt , $(BIN))
TIME = $(patsubst bin/%,out/%.time, $(BIN))
CSV = $(patsubst bin/%,out/%.csv , $(BIN))

CSV_SUMMARY = out/bench.csv
MD_SUMMARY = out/bench.md

PATH1 = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
PATH2 = /run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

# run
.PHONY: run
run: $(TXT) $(TIME)  ## run all
out/%.txt out/%.time &: bin/%
	@mkdir -p $(@D)
	command time -v $< $(PATH1) $(PATH2) > out/$*.txt 2> out/$*.time

.PHONY: clean_run
clean_run:  ## clean run files
	rm -f $(TXT) $(TIME)

# bench
.PHONY: bench bench_md
bench: $(CSV_SUMMARY)  ## benchmark all in csv format, this only runs benchmarks that have not updated
bench_md: $(MD_SUMMARY)  ## benchmark all in markdown format, note that this forces all benchmarks to run
out/%.csv: bin/%
	@mkdir -p $(@D)
	hyperfine --warmup 1 '$< $(PATH1) $(PATH2)' --export-csv $@ --command-name $*
.NOTPARALLEL: $(CSV_SUMMARY)
$(CSV_SUMMARY): $(CSV)
	cat $^ | sort -un -t, -k2 > $@
$(MD_SUMMARY): $(BIN)
	hyperfine --shell=none --warmup 1 --sort mean-time --export-markdown $@ $(foreach bin,$^,--command-name $(notdir $(bin)) '$(bin) $(PATH1) $(PATH2)')

.PHONY: clean_bench
clean_bench:  ## clean benchmark files
	rm -f $(CSV) $(CSV_SUMMARY) $(MD_SUMMARY)

# misc #########################################################################

# test
.PHONY: test
test: $(TXT)  ## test all
	for i in $(TXT); do difft out/diffpath_c.txt $$i; done

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
	rm -f bin/.DS_Store out/.DS_Store
	rmdir --ignore-fail-on-non-empty bin out 2> /dev/null || true

.PHONY: help
# modified from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@awk 'BEGIN{w=0;n=0}{while(match($$0,/\\$$/)){sub(/\\$$/,"");getline nextLine;$$0=$$0 nextLine}if(/^[[:alnum:]_-]+:.*##.*$$/){n++;split($$0,cols[n],":.*##");l=length(cols[n][1]);if(w<l)w=l}}END{for(i=1;i<=n;i++)printf"\033[1m\033[93m%-*s\033[0m%s\n",w+1,cols[i][1]":",cols[i][2]}' $(MAKEFILE_LIST)

print-%:
	$(info $* = $($*))
