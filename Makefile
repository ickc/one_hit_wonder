.DEFAULT_GOAL = help
.PHONY: all
all: compile run test  ## compile, run, and test

# compile ######################################################################

SRC = $(wildcard \
	src/*.c \
	src/*.cpp \
	src/*.go \
	src/*.hs \
	src/*.lua \
	src/*.py \
	src/*.rs \
	src/*.sh \
	src/*.ts \
)
BIN = $(patsubst src/%,bin/%,$(subst .,_,$(SRC)))

.PHONY: compile
compile: $(BIN)  ## compile all

# language specific ============================================================

define symlink
	chmod +x $<
	@mkdir -p $(@D)
	ln -f $< $@
endef

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
# this depends on 3rd party: `luarocks install luafilesystem --local`
bin/%_lua: src/%.lua
	$(symlink)
bin/%_py: src/%.py
	$(symlink)
bin/%_rs: src/%.rs
	@mkdir -p $(@D)
	rustc -o $@ -C opt-level=3 -C target-cpu=native --edition=2021 $<
bin/%_sh: src/%.sh
	$(symlink)
bin/%_ts: src/%.ts node_modules/
	@mkdir -p $(@D)
	tsc $< --outDir $(@D) --target esnext --module nodenext --strict --types node --removeComments
	mv bin/$*.js $@
	chmod +x $@
node_modules/:
	npm install @types/node --no-save

.PHONY: clean_hs clean_compile
clean_hs:  ## clean auxiliary Haskell files
	rm -f src/*.o src/*.hi
clean_ts:  ## clean auxiliary TypeScript files
	rm -rf node_modules
clean_compile: clean_hs clean_ts  ## clean compiled files
	rm -f $(BIN)

# format =======================================================================

.PHONY: \
	format_c \
	format_cpp \
	format_hs \
	format_lua \
	format_py \
	format_rs \
	format_sh \
	format_ts \
	format
format: \
	format_c \
	format_cpp \
	format_hs \
	format_lua \
	format_py \
	format_rs \
	format_sh \
	format_ts \
	## format all
format_c:  ## format C files
	find src -type f -name '*.c' -exec clang-format -i -style=WebKit {} +
format_cpp:  ## format C++ files
	find src -type f -name '*.cpp' -exec clang-format -i -style=WebKit {} +
format_go:  ## format Go files
	find src -type f -name '*.go' -exec gofmt -w {} +
format_hs:  ## format Haskell files
	find src -type f -name '*.hs' -exec stylish-haskell -i {} +
format_lua:  ## format Lua files
	find src -type f -name '*.lua' -exec stylua --indent-type Spaces {} +
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
format_ts:  ## format TypeScript files
	find src -type f -name '*.ts' -exec prettier --write {} +

# run & benchmark #############################################################

TXT  = $(patsubst bin/%,out/%.txt , $(BIN))
TIME = $(patsubst bin/%,out/%.time, $(BIN))
CSV  = $(patsubst bin/%,out/%.csv , $(BIN))

CSV_SUMMARY = out/bench.csv
MD_SUMMARY  = out/bench.md

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
