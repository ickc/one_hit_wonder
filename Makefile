INCLUDEFILE = .env
include $(INCLUDEFILE)
DEVBOXS = $(wildcard envs/*/devbox.*)

.DEFAULT_GOAL = help
.PHONY: all
all: compile run test  ## compile, run, and test

# compile ######################################################################

EXT =

# C
EXT += c
SRC_c = $(wildcard src/*.c)
COMPILER_c = $(GCC) $(CLANG)
BIN_c = $(foreach compiler,$(COMPILER_c),$(patsubst src/%,bin/%_$(notdir $(compiler)),$(subst .,_,$(SRC_c))))
bin/%_c_$(notdir $(GCC)): src/%.c
	@mkdir -p $(@D)
	$(GCC) -o $@ -O3 -march=$(GCC_MARCH) -mtune=native -std=c23 $<
bin/%_c_$(notdir $(CLANG)): src/%.c
	@mkdir -p $(@D)
	$(CLANG) -o $@ -O3 -march=native -mtune=native -std=c23 $<
ifdef CLANG_SYSTEM
BIN_c += $(patsubst src/%,bin/%_clang_system,$(subst .,_,$(SRC_c)))
bin/%_c_clang_system: src/%.c
	@mkdir -p $(@D)
	$(CLANG_SYSTEM) -o $@ -O3 -march=native -mtune=native -std=c17 $<
endif

.PHONY: clean_c format_c
clean_c:  ## clean C binaries
	rm -f $(BIN_c)
format_c:  ## format C files
	find src -type f -name '*.c' -exec \
		$(CLANG_FORMAT) -i -style=WebKit {} +

# C++
EXT += cpp
SRC_cpp = $(wildcard src/*.cpp)
COMPILER_cpp = $(GXX) $(CLANGXX)
BIN_cpp = $(foreach compiler,$(COMPILER_cpp),$(patsubst src/%,bin/%_$(notdir $(compiler)),$(subst .,_,$(SRC_cpp))))
bin/%_cpp_$(notdir $(GXX)): src/%.cpp
	@mkdir -p $(@D)
	$(GXX) -o $@ -O3 -march=$(GCC_MARCH) -mtune=native -std=c++23 $<
bin/%_cpp_$(notdir $(CLANGXX)): src/%.cpp
	@mkdir -p $(@D)
	$(CLANGXX) -o $@ -O3 -march=native -mtune=native -std=c++23 $<
ifdef CLANGXX_SYSTEM
BIN_cpp += $(patsubst src/%,bin/%_clang++_system,$(subst .,_,$(SRC_cpp)))
bin/%_cpp_clang++_system: src/%.cpp
	@mkdir -p $(@D)
	$(CLANGXX_SYSTEM) -o $@ -O3 -march=native -mtune=native -std=c++20 $<
endif

.PHONY: clean_cpp format_cpp
clean_cpp:  ## clean C++ binaries
	rm -f $(BIN_cpp)
format_cpp:  ## format C++ files
	find src -type f -name '*.cpp' -exec \
		$(CLANG_FORMAT) -i -style=WebKit {} +

# Go
EXT += go
SRC_go = $(wildcard src/*.go)
COMPILER_go = $(GO)
BIN_go = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_go)))
bin/%_go: src/%.go
	@mkdir -p $(@D)
	$(GO) build -o $@ -ldflags="-s -w" -trimpath $<
.PHONY: clean_go format_go
clean_go:  ## clean Go binaries
	rm -f $(BIN_go)
format_go:  ## format Go files
	find src -type f -name '*.go' -exec \
		$(GOFMT) -w {} +

# Haskell
EXT += hs
SRC_hs = $(wildcard src/*.hs)
COMPILER_hs = $(GHC)
BIN_hs = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_hs)))
bin/%_hs: src/%.hs
	@mkdir -p $(@D)
	$(GHC) -o $@ -O2 $<
.PHONY: clean_hs format_hs
clean_hs:  ## clean Haskell files
	rm -f $(BIN_hs) src/*.o src/*.hi
format_hs:  ## format Haskell files
	find src -type f -name '*.hs' -exec \
		$(STYLISH_HASKELL) -i {} +

# Lua
EXT += lua
SRC_lua = $(wildcard src/*.lua)
COMPILER_lua = $(LUA) $(LUAJIT)
BIN_lua = $(foreach compiler,$(COMPILER_lua),$(patsubst src/%,bin/%_$(notdir $(compiler)),$(subst .,_,$(SRC_lua))))
# this depends on 3rd party: `luarocks install luafilesystem --local`
bin/%_lua_$(notdir $(LUA)): src/%.lua
	@mkdir -p $(@D)
	@echo "#!$(LUA)" > $@
	@echo "package.cpath = \"$(LUA_LUA_CPATH);\" .. package.cpath" >> $@
	@cat $< >> $@
	@chmod +x $@
bin/%_lua_$(notdir $(LUAJIT)): src/%.lua
	@mkdir -p $(@D)
	@echo "#!$(LUAJIT)" > $@
	@echo "package.cpath = \"$(LUAJIT_LUA_CPATH);\" .. package.cpath" >> $@
	@cat $< >> $@
	@chmod +x $@
.PHONY: clean_lua format_lua
clean_lua:  ## clean Lua binaries
	rm -f $(BIN_lua)
format_lua:  ## format Lua files
	find src -type f -name '*.lua' -exec \
		$(STYLUA) --indent-type Spaces {} +

# Python
EXT += py
SRC_py = $(wildcard src/*.py)
COMPILER_py = $(PYTHON) $(PYPY)
BIN_py = $(foreach compiler,$(COMPILER_py),$(patsubst src/%,bin/%_$(notdir $(compiler)),$(subst .,_,$(SRC_py))))
bin/%_py_$(notdir $(PYTHON)): src/%.py
	@mkdir -p $(@D)
	@echo "#!$(PYTHON)" > $@
	@cat $< >> $@
	@chmod +x $@
bin/%_py_$(notdir $(PYPY)): src/%.py
	@mkdir -p $(@D)
	@echo "#!$(PYPY)" > $@
	@cat $< >> $@
	@chmod +x $@
BIN_py += $(foreach compiler,$(COMPILER_c),$(patsubst src/%,bin/%_cython_$(notdir $(compiler)),$(subst .,_,$(SRC_py))))
bin/%_py_cython_$(notdir $(GCC)): src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CC=$(GCC) $(CYTHONIZE) -i $@.py --3str --no-docstrings
	@rm -f $@.py $@.c
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
bin/%_py_cython_$(notdir $(CLANG)): src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CC=$(CLANG) $(CYTHONIZE) -i $@.py --3str --no-docstrings
	@rm -f $@.py $@.c
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
BIN_py += $(patsubst src/%.py,bin/%_py_cython_gxx,$(SRC_py))
bin/%_py_cython_gxx: src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CXX=$(GXX) $(CYTHONIZE) -i $@.py --3str --no-docstrings --cplus
	@rm -f $@.py $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
BIN_py += $(patsubst src/%.py,bin/%_py_cython_clangxx,$(SRC_py))
bin/%_py_cython_clangxx: src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CXX=$(CLANGXX) $(CYTHONIZE) -i $@.py --3str --no-docstrings --cplus
	@rm -f $@.py $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
ifdef NUITKA_PYTHON
BIN_py += $(patsubst src/%,bin/%_nuitka,$(subst .,_,$(SRC_py)))
bin/%_py_nuitka: src/%.py
	@mkdir -p $(@D)
	PYTHONPATH=$(NUITKA_PYTHONPATH) $(NUITKA_PYTHON) -m nuitka --standalone --assume-yes-for-downloads --static-libpython=yes --output-dir=$(@D) --output-filename=$*_py_nuitka $<
	ln -sf diffpath.dist/$*_py_nuitka $@
endif
ifdef PYTHON_SYSTEM
BIN_py += $(patsubst src/%,bin/%_python_system,$(subst .,_,$(SRC_py)))
bin/%_py_python_system: src/%.py
	@mkdir -p $(@D)
	@echo "#!$(PYTHON_SYSTEM)" > $@
	@cat $< >> $@
	@chmod +x $@
endif
.PHONY: clean_py format_py
clean_py:  ## clean Python binaries
	rm -f $(BIN_py)
format_py:  ## format Python files
	$(AUTOFLAKE) --in-place --recursive --expand-star-imports --remove-all-unused-imports --ignore-init-module-imports --remove-duplicate-keys --remove-unused-variables src
	$(BLACK) src
	$(ISORT) src

# Rust
EXT += rs
SRC_rs = $(wildcard src/*.rs)
COMPILER_rs = $(RUSTC)
BIN_rs = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_rs)))
bin/%_rs: src/%.rs
	@mkdir -p $(@D)
	$(RUSTC) -o $@ -C opt-level=3 -C target-cpu=native --edition=2021 $<
.PHONY: clean_rs format_rs
clean_rs:  ## clean Rust binaries
	rm -f $(BIN_rs)
format_rs:  ## format Rust files
	find src -type f -name '*.rs' -exec \
		$(RUSTFMT) {} +

# bash
EXT += sh
SRC_sh = $(wildcard src/*.sh)
COMPILER_sh = $(BASH)
BIN_sh = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_sh)))
bin/%_sh: src/%.sh
	@mkdir -p $(@D)
	@echo "#!$(BASH)" > $@
	@cat $< >> $@
	@chmod +x $@
.PHONY: clean_sh format_sh
clean_sh:  ## clean Shell binaries
	rm -f $(BIN_sh)
format_sh:  ## format Shell files
	find . src -maxdepth 1 -type f -name '*.sh' \
	-exec sed -i -E \
		-e 's/\$$([a-zA-Z_][a-zA-Z0-9_]*)/$${\1}/g' \
		-e 's/([^[])\[ ([^]]+) \]/\1[[ \2 ]]/g' \
		{} + \
	-exec $(SHFMT) \
		--write \
		--simplify \
		--indent 4 \
		--case-indent \
		--space-redirects \
		{} +

# TypeScript
EXT += ts
SRC_ts = $(wildcard src/*.ts)
COMPILER_ts = $(TSC)
BIN_ts = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_ts)))
bin/%_ts: src/%.ts node_modules/
	@mkdir -p $(@D)
	$(TSC) $< --outDir $(@D) --target esnext --module nodenext --strict --types node --removeComments
	@echo "#!$(NODE)" > $@
	@cat bin/$*.js >> $@
	@rm -f bin/$*.js
	@chmod +x $@
node_modules/:
	$(NPM) install @types/node --no-save
.PHONY: clean_ts format_ts
clean_ts:  ## clean auxiliary TypeScript files
	rm -f $(BIN_ts)
Clean_ts:  ## clean node modules
	rm -rf node_modules
format_ts:  ## format TypeScript files
	find src -type f -name '*.ts' -exec \
		$(PRETTIER) --write {} +

# all

BIN = $(foreach ext,$(EXT),$(BIN_$(ext)))
COMPILER = $(foreach ext,$(EXT),$(COMPILER_$(ext)))

.PHONY: compile clean_compile format compiler_version
compile: $(BIN)  ## compile all
clean_compile: $(foreach ext,$(EXT),clean_$(ext))  ## clean compiled files
format: $(foreach ext,$(EXT),format_$(ext))  ## format all
compiler_version:  ## show compilers versions
	@for compiler in $(COMPILER); do \
		 eval printf %.0s= '{1..'"$${COLUMNS:-72}"\}; \
		 echo; \
		which $$compiler; \
		case $$compiler in \
			*/go) $$compiler version ;; \
			*/lua) $$compiler -v ;; \
			*/luajit) $$compiler -v ;; \
			*) $$compiler --version ;; \
		esac; \
	done

# run & benchmark #############################################################

TXT = $(patsubst bin/%,out/%.txt , $(BIN))
TIME = $(patsubst bin/%,out/%.time, $(BIN))
CSV = $(patsubst bin/%,out/%.csv , $(BIN))

CSV_SUMMARY = out/bench.csv
MD_SUMMARY = out/bench.md

PATH1 = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
PATH2 = ~/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin

# run
.PHONY: run
run: $(TXT) $(TIME)  ## run all
out/%.txt out/%.time &: bin/%
	@mkdir -p $(@D)
	$(GNUTIME) -o out/$*.time -v $< $(PATH1) $(PATH2) > out/$*.txt

.PHONY: clean_run
clean_run:  ## clean run files
	rm -f $(TXT) $(TIME)

# bench
.PHONY: bench bench_md
bench: $(CSV_SUMMARY)  ## benchmark all in csv format, this only runs benchmarks that have not updated
bench_md: $(MD_SUMMARY)  ## benchmark all in markdown format, note that this forces all benchmarks to run
out/%.csv: bin/%
	@mkdir -p $(@D)
	$(HYPERFINE) --warmup 1 '$< $(PATH1) $(PATH2)' --export-csv $@ --command-name $*
.NOTPARALLEL: $(CSV_SUMMARY)
$(CSV_SUMMARY): $(CSV)
	cat $^ | sort -un -t, -k2 > $@
$(MD_SUMMARY): $(BIN)
	$(HYPERFINE) --shell=none --warmup 1 --sort mean-time --export-markdown $@ $(foreach bin,$^,--command-name $(notdir $(bin)) '$(bin) $(PATH1) $(PATH2)')

.PHONY: clean_bench
clean_bench:  ## clean benchmark files
	rm -f $(CSV) $(CSV_SUMMARY) $(MD_SUMMARY)

# misc #########################################################################

.PHONY: build update test size list_link clean Clean help
build: $(INCLUDEFILE)  ## prepare environments using nix & devbox (should be triggered automatically)
$(INCLUDEFILE): env.sh $(DEVBOXS)
	./$< $@
update:  ## update environments using nix & devbox
	devbox update --all-projects
test: $(TXT)  ## test all
	for i in $(TXT); do \
		$(DIFFT) out/diffpath_c_gcc.txt $$i; \
	done
size:  ## show binary sizes
	@ls -lh bin | sort -hk5
	@du -sh bin/diffpath.dist || true
list_link:  ## list dynamically linked libraries
	if [[ $$(uname) == Darwin ]]; then \
		find bin -type f -executable -exec otool -L {} +; \
	else \
		find bin -type f -executable -exec ldd {} + || true; \
	fi
clean: \
	clean_compile \
	clean_run \
	clean_bench \
	## clean all
	rm -f $(INCLUDEFILE) bin/.DS_Store out/.DS_Store
	rm -rf bin/diffpath.dist
	ls bin out 2>/dev/null || true
	rm -rf bin out
Clean: clean Clean_ts  ## Clean the environments too (this triggers redownload & rebuild next time!)
	find envs -type d -name '.devbox' -exec rm -rf {} +
	devbox run -- nix store gc --extra-experimental-features nix-command
# modified from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:  ## print this help message
	@awk 'BEGIN{w=0;n=0}{while(match($$0,/\\$$/)){sub(/\\$$/,"");getline nextLine;$$0=$$0 nextLine}if(/^[[:alnum:]_-]+:.*##.*$$/){n++;split($$0,cols[n],":.*##");l=length(cols[n][1]);if(w<l)w=l}}END{for(i=1;i<=n;i++)printf"\033[1m\033[93m%-*s\033[0m%s\n",w+1,cols[i][1]":",cols[i][2]}' $(MAKEFILE_LIST)
print-%:
	$(info $* = $($*))
