INCLUDEFILE = .env
include $(INCLUDEFILE)
DEVBOXS_JSON = $(wildcard envs/*/devbox.json)
DEVBOXS_LOCK = $(wildcard envs/*/devbox.lock)
DEVBOXS = $(DEVBOXS_JSON) $(DEVBOXS_LOCK)

UNAME = $(shell uname -s)

.DEFAULT_GOAL = help
.PHONY: all
all: compile run test  ## compile, run, and test

# compile ######################################################################

C_COMMON_FLAGS = \
	-DNDEBUG \
	-fwrapv \
	-mtune=native \
	-O3 \
	-Wall \
	-Wsign-compare \
	-Wunreachable-code
GCC_FLAGS = $(C_COMMON_FLAGS) -march=$(GCC_MARCH) -std=c23
CLANG_FLAGS = $(C_COMMON_FLAGS) -march=native -std=c23
CLANG_FLAGS_SYSTEM = $(C_COMMON_FLAGS) -march=native -std=c17
GXX_FLAGS = $(C_COMMON_FLAGS) -march=$(GCC_MARCH) -std=c++23
CLANGXX_FLAGS = $(C_COMMON_FLAGS) -march=native -std=c++23
CLANGXX_FLAGS_SYSTEM = $(C_COMMON_FLAGS) -march=native -std=c++20
CYTHON_FLAGS = --3str --no-docstrings
CYTHONXX_FLAGS = $(CYTHON_FLAGS) --cplus

EXT =

# C
EXT += c
SRC_c = $(wildcard src/*.c)
COMPILER_c = $(GCC) $(CLANG)
BIN_c = $(foreach compiler,$(COMPILER_c),$(patsubst src/%,bin/%_$(notdir $(compiler)),$(subst .,_,$(SRC_c))))
bin/%_c_$(notdir $(GCC)): src/%.c
	@mkdir -p $(@D)
	$(GCC) $< -o $@ $(GCC_FLAGS)
bin/%_c_$(notdir $(CLANG)): src/%.c
	@mkdir -p $(@D)
	$(CLANG) $< -o $@ $(CLANG_FLAGS)
ifdef CLANG_SYSTEM
BIN_c += $(patsubst src/%,bin/%_clang_system,$(subst .,_,$(SRC_c)))
bin/%_c_clang_system: src/%.c
	@mkdir -p $(@D)
	$(CLANG_SYSTEM) $< -o $@ $(CLANG_FLAGS_SYSTEM)
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
	$(GXX) $< -o $@ $(GXX_FLAGS)
bin/%_cpp_$(notdir $(CLANGXX)): src/%.cpp
	@mkdir -p $(@D)
	$(CLANGXX) $< -o $@ $(CLANGXX_FLAGS)
ifdef CLANGXX_SYSTEM
BIN_cpp += $(patsubst src/%,bin/%_clang++_system,$(subst .,_,$(SRC_cpp)))
bin/%_cpp_clang++_system: src/%.cpp
	@mkdir -p $(@D)
	$(CLANGXX_SYSTEM) $< -o $@ $(CLANGXX_FLAGS_SYSTEM)
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
.INTERMEDIATE: bin/%.o bin/%.hi
bin/%_hs: src/%.hs
	@mkdir -p $(@D)
	$(GHC) -o $@ -O2 $<
	@rm -f src/$*.o src/$*.hi
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
	CC=$(GCC) CFLAGS='$(GCC_FLAGS)'  \
		$(CYTHONIZE) -i $@.py $(CYTHON_FLAGS)
	@rm -f $@.py $@.c
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
bin/%_py_cython_$(notdir $(CLANG)): src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CC=$(CLANG) CFLAGS='$(CLANG_FLAGS)' \
		$(CYTHONIZE) -i $@.py $(CYTHON_FLAGS)
	@rm -f $@.py $@.c
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
BIN_py += $(patsubst src/%.py,bin/%_py_cython_gxx,$(SRC_py))
bin/%_py_cython_gxx: src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CC=$(GXX) CFLAGS='$(GXX_FLAGS)' \
	CXX=$(GXX) CXXFLAGS='$(GXX_FLAGS)' \
		$(CYTHONIZE) -i $@.py $(CYTHONXX_FLAGS)
	@rm -f $@.py $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
BIN_py += $(patsubst src/%.py,bin/%_py_cython_clangxx,$(SRC_py))
bin/%_py_cython_clangxx: src/%.py
	@mkdir -p $(@D)
	@ln -sf ../$< $@.py
	CC=$(CLANGXX) CFLAGS='$(CLANGXX_FLAGS)' \
	CXX=$(CLANGXX) CXXFLAGS='$(CLANGXX_FLAGS)' \
		$(CYTHONIZE) -i $@.py $(CYTHONXX_FLAGS)
	@rm -f $@.py $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
ifdef NUITKA_PYTHON
# https://github.com/Nuitka/Nuitka/issues/2987#issuecomment-2255262307
NUITKA_FLAGS = --assume-yes-for-downloads --standalone --static-libpython=no
# skip onefile build if Darwin and PYTHON_METHOD is devbox
# as nix often have code-sign issue
ifeq ($(UNAME)-$(PYTHON_METHOD), Darwin-devbox)
BIN_py += $(patsubst src/%,bin/%_nuitka,$(subst .,_,$(SRC_py)))
bin/%_py_nuitka: src/%.py
	@mkdir -p $(@D)
	PYTHONPATH=$(NUITKA_PYTHONPATH) $(NUITKA_PYTHON) -m nuitka $< --output-dir=$(@D) --output-filename=$*_py_nuitka $(NUITKA_FLAGS)
	ln -sf $*.dist/$*_py_nuitka $@
else
BIN_py += $(patsubst src/%,bin/%_nuitka_onefile,$(subst .,_,$(SRC_py)))
bin/%_py_nuitka_onefile: src/%.py
	@mkdir -p $(@D)
	PYTHONPATH=$(NUITKA_PYTHONPATH) $(NUITKA_PYTHON) -m nuitka $< --output-dir=$(@D) --output-filename=$*_py_nuitka_onefile $(NUITKA_FLAGS) --onefile
	@rm -rf bin/diffpath.build bin/diffpath.dist bin/diffpath.onefile-build
BIN_py += $(patsubst src/%,bin/%_nuitka,$(subst .,_,$(SRC_py)))
bin/%_py_nuitka: src/%.py bin/%_py_nuitka_onefile
	@mkdir -p $(@D)
	PYTHONPATH=$(NUITKA_PYTHONPATH) $(NUITKA_PYTHON) -m nuitka $< --output-dir=$(@D) --output-filename=$*_py_nuitka $(NUITKA_FLAGS)
	ln -sf $*.dist/$*_py_nuitka $@
endif
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
	$(AUTOFLAKE) --in-place --recursive --expand-star-imports --remove-all-unused-imports --ignore-init-module-imports --remove-duplicate-keys --remove-unused-variables src util
	$(BLACK) src util
	$(ISORT) src util

# Cython
EXT += pyx
SRC_pyx = $(wildcard src/*.pyx)
BIN_pyx =
# Cython on Darwin hardcoded to use clang++ for linking
ifneq ($(UNAME),Darwin)
BIN_pyx += $(patsubst src/%.pyx,bin/%_pyx_cython_gxx,$(SRC_pyx))
bin/%_pyx_cython_gxx: src/%.pyx
	@mkdir -p $(@D)
	@ln -sf ../$< $@.pyx
	CC=$(GXX) CFLAGS='$(GXX_FLAGS)' \
	CXX=$(GXX) CXXFLAGS='$(GXX_FLAGS)' \
		$(CYTHONIZE) -i $@.pyx $(CYTHONXX_FLAGS)
	@rm -f $@.pyx $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
endif
BIN_pyx += $(patsubst src/%.pyx,bin/%_pyx_cython_clangxx,$(SRC_pyx))
bin/%_pyx_cython_clangxx: src/%.pyx
	@mkdir -p $(@D)
	@ln -sf ../$< $@.pyx
	CC=$(CLANGXX) CFLAGS='$(CLANGXX_FLAGS)' \
	CXX=$(CLANGXX) CXXFLAGS='$(CLANGXX_FLAGS)' \
		$(CYTHONIZE) -i $@.pyx $(CYTHONXX_FLAGS)
	@rm -f $@.pyx $@.cpp
	@printf "#!$(CYTHON_PYTHON)\nfrom $(@F) import main\nmain()" > $@
	@chmod +x $@
ifdef CLANGXX_SYSTEM
BIN_pyx += $(patsubst src/%.pyx,bin/%_pyx_cython_clangxx_system,$(SRC_pyx))
bin/%_pyx_cython_clangxx_system: src/%.pyx
	@mkdir -p $(@D)
	@ln -sf ../$< $@.pyx
	CC=$(CLANGXX_SYSTEM) CFLAGS='$(CLANGXX_FLAGS_SYSTEM)' \
	CXX=$(CLANGXX_SYSTEM) CXXFLAGS='$(CLANGXX_FLAGS_SYSTEM)' \
		$(CYTHONIZE) -i $@.pyx $(CYTHONXX_FLAGS)
	@rm -f $@.pyx $@.cpp
	@printf '#!$(CYTHON_PYTHON)\nimport sys\nfrom $(@F) import main\nmain()\n' > $@
	@chmod +x $@
endif
.PHONY: clean_pyx format_pyx
clean_pyx:  ## clean Cython binaries
	rm -f $(BIN_pyx)

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
ifdef BASH_SYSTEM
BIN_sh += $(patsubst src/%,bin/%_system,$(subst .,_,$(SRC_sh)))
bin/%_sh_system: src/%.sh
	@mkdir -p $(@D)
	@echo "#!$(BASH_SYSTEM)" > $@
	@cat $< >> $@
	@chmod +x $@
endif
.PHONY: clean_sh format_sh
clean_sh:  ## clean Shell binaries
	rm -f $(BIN_sh)
format_sh:  ## format Shell files
	find src util -type f -name '*.sh' \
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
# zsh
EXT += zsh
SRC_zsh = $(wildcard src/*.zsh)
COMPILER_zsh = $(ZSH)
BIN_zsh = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_zsh)))
bin/%_zsh: src/%.zsh
	@mkdir -p $(@D)
	@echo "#!$(ZSH)" > $@
	@cat $< >> $@
	@chmod +x $@
ifdef ZSH_SYSTEM
BIN_zsh += $(patsubst src/%,bin/%_system,$(subst .,_,$(SRC_zsh)))
bin/%_zsh_system: src/%.zsh
	@mkdir -p $(@D)
	@echo "#!$(ZSH_SYSTEM)" > $@
	@cat $< >> $@
	@chmod +x $@
endif
.PHONY: clean_zsh format_zsh
clean_zsh:  ## clean Zsh binaries
	rm -f $(BIN_zsh)
format_zsh:  ## format Zsh files
	find src util -type f -name '*.zsh' \
	-exec sed -i -E \
		-e 's/\$$([a-zA-Z_][a-zA-Z0-9_]*)/$${\1}/g' \
		-e 's/([^[])\[ ([^]]+) \]/\1[[ \2 ]]/g' \
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
.PHONY: clean_ts Clean_ts format_ts
clean_ts:  ## clean auxiliary TypeScript files
	rm -f $(BIN_ts)
Clean_ts:  ## clean node modules
	rm -rf node_modules
format_ts:  ## format TypeScript files
	find src -type f -name '*.ts' -exec \
		$(PRETTIER) --write {} +

# Perl
EXT += pl
SRC_pl = $(wildcard src/*.pl)
COMPILER_pl = $(PERL)
BIN_pl = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_pl)))
bin/%_pl: src/%.pl
	@mkdir -p $(@D)
	@echo "#!$(PERL)" > $@
	@cat $< >> $@
	@chmod +x $@
ifdef PERL_SYSTEM
BIN_pl += $(patsubst src/%,bin/%_system,$(subst .,_,$(SRC_pl)))
bin/%_pl_system: src/%.pl
	@mkdir -p $(@D)
	@echo "#!$(PERL_SYSTEM)" > $@
	@cat $< >> $@
	@chmod +x $@
endif
.PHONY: clean_pl format_pl
clean_pl:  ## clean generated PERL scripts
	rm -f $(BIN_pl)
format_pl:  ## format PERL files
	find src -type f -name '*.pl' -exec \
		$(PERLTIDY) -b {} +
	find src -type f -name '*.pl.bak' -delete

# C#
EXT += cs
SRC_cs = $(wildcard src/*.cs)
COMPILER_cs = $(DOTNET)
BIN_cs = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_cs)))
.INTERMEDIATE: bin/%.pdb src/bin src/obj
bin/%_cs: src/%.csproj src/%.cs
	@mkdir -p $(@D)
	$(DOTNET) publish $< -o src/bin --self-contained true --nologo --configuration Release -p:PublishSingleFile=true -p:PublishTrimmed=true
	@mv src/bin/$* $@
	@rm -f bin/%*.pdb
	@rm -rf src/bin src/obj
.PHONY: clean_cs format_cs
clean_cs:  ## clean C# binaries
	rm -f $(BIN_cs) bin/*.pdb
	rm -rf src/bin src/obj
format_cs:  ## format C# files
	find src -type f -name '*.csproj' -exec \
		$(DOTNET) format {} +

# Objective C
ifeq ($(UNAME),Darwin)
ifdef CLANG_SYSTEM
EXT += m
SRC_m = $(wildcard src/*.m)
COMPILER_m = $(CLANG_SYSTEM)
BIN_m = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_m)))
bin/%_m: src/%.m
	@mkdir -p $(@D)
	$(CLANG_SYSTEM) $< -o $@ $(CLANG_FLAGS_SYSTEM) -framework Foundation
.PHONY: clean_m format_m
clean_m:  ## clean Objective C binaries
	rm -f $(BIN_m)
format_m:  ## format Objective C files
	find src -type f -name '*.m' -exec \
		$(CLANG_FORMAT) -i -style=WebKit {} +
endif
endif

# Julia
EXT += jl
SRC_jl = $(wildcard src/*.jl)
COMPILER_jl = $(JULIA)
BIN_jl = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_jl)))
bin/%_jl: src/%.jl
	@mkdir -p $(@D)
	@echo '#!$(JULIA)' > $@
	@cat $< >> $@
	@chmod +x $@
$(JULIA_DEPOT_PATH):
	$(JULIA) -e 'using Pkg; Pkg.add("JuliaFormatter")'
.PHONY: clean_jl Clean_jl format_jl
clean_jl:  ## clean Julia binaries
	rm -f $(BIN_jl)
Clean_jl:  ## clean Julia packages
	rm -rf $(JULIA_DEPOT_PATH)
format_jl: $(JULIA_DEPOT_PATH)  ## format Julia files
	$(JULIA) -e 'using JuliaFormatter; format("src", style=SciMLStyle(), margin=120)'

# Java
EXT += java
SRC_java = $(wildcard src/*.java)
COMPILER_java = $(JAVA)
BIN_java = $(patsubst src/%,bin/%,$(subst .,_,$(SRC_java)))
bin/%_java: src/%.java
	@mkdir -p $(@D)
	$(JAVAC) -d $(@D) $<
	$(JAR) cfm $@.jar <(echo 'Main-Class: $*') -C $(@D) $*.class
	@rm -f $(@D)/$*.class
	@echo '#!$(JAVA) -jar' > $@
	@cat $@.jar >> $@
	@rm -f $@.jar
	@chmod +x $@
.PHONY: clean_java format_java
clean_java:  ## clean Java binaries
	rm -f $(BIN_java)
format_java:  ## format Java files
	find src -type f -name '*.java' -exec \
		$(GOOGLE_JAVA_FORMAT) --aosp -i {} +

# all

BIN = $(foreach ext,$(EXT),$(BIN_$(ext)))
COMPILER = $(foreach ext,$(EXT),$(COMPILER_$(ext)))

.PHONY: compile clean_compile format compiler_version
compile: $(BIN)  ## compile all
clean_compile: $(foreach ext,$(EXT),clean_$(ext))  ## clean compiled files
format: $(foreach ext,$(EXT),format_$(ext))  ## format all
compiler_version:  ## show compilers versions
	@for compiler in $(COMPILER); do \
		printf '%.0s—' {1..80}; echo; \
		which $$compiler; \
		case $$compiler in \
			*/go) $$compiler version ;; \
			*/lua) $$compiler -v ;; \
			*/luajit) $$compiler -v ;; \
			*) $$compiler --version ;; \
		esac; \
	done

# run & benchmark #############################################################

# different kinds of programs, e.g. PROGRAMS = diffpath gitignored ...
PROGRAMS = $(sort $(foreach prog,$(BIN),$(firstword $(subst _, ,$(notdir $(prog))))))
CSV_SUMMARY = $(patsubst %,out/%.csv,$(PROGRAMS))
MD_SUMMARY = $(patsubst %,out/%.md,$(PROGRAMS))

OUT = $(patsubst bin/%,out/%.out,$(BIN))
ERR = $(patsubst bin/%,out/%.err,$(BIN))
TIME = $(patsubst bin/%,out/%.time,$(BIN))
CSV = $(patsubst bin/%,out/%.csv,$(BIN))

ARGS_RUN_diffpath = /usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin $(HOME)/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin
ARGS_BENCH_diffpath = $(ARGS_RUN_diffpath)
ARGS_BENCH_gitignored = $(HOME)/git/fork
ARGS_RUN_gitignored = $(ARGS_BENCH_gitignored) -d

define PROGRAM_DISPATCH
BIN_$(1) = $(filter bin/$(1)_%,$(BIN))
OUT_$(1) = $(filter out/$(1)_%,$(OUT))
ERR_$(1) = $(filter out/$(1)_%,$(ERR))
CSV_$(1) = $(filter out/$(1)_%,$(CSV))

out/$(1)_%.out out/$(1)_%.err out/$(1)_%.time &: bin/$(1)_%
	@mkdir -p $$(@D)
	$(GNUTIME) -o out/$(1)_$$*.time -v $$< $$(ARGS_RUN_$(1)) > out/$(1)_$$*.out 2> out/$(1)_$$*.err

out/$(1)_%.csv: bin/$(1)_%
	@mkdir -p $$(@D)
	$(HYPERFINE) --warmup 1 '$$< $$(ARGS_BENCH_$(1))' --export-csv $$@ --command-name $(1)_$$*
out/$(1).csv: $$(CSV_$(1))
	cat $$^ | sort -un -t, -k2 > $$@
out/$(1).md: $$(BIN_$(1))
	$(HYPERFINE) --shell=none --warmup 1 --sort mean-time --export-markdown $$@ $$(foreach bin,$$^,--command-name $$(notdir $$(bin)) '$$(bin) $$(ARGS_BENCH_$(1))')
endef
$(foreach program,$(PROGRAMS),$(eval $(call PROGRAM_DISPATCH,$(program))))

.PHONY: run clean_run bench bench_md clean_bench
run: $(OUT) $(ERR) $(TIME)  ## run all
clean_run:  ## clean run files
	rm -f $(OUT) $(TIME)
bench: $(CSV_SUMMARY)  ## benchmark all in csv format, this only runs benchmarks that have not updated
bench_md: $(MD_SUMMARY)  ## benchmark all in markdown format, note that this forces all benchmarks to run
.NOTPARALLEL: $(CSV_SUMMARY) bench bench_md
clean_bench:  ## clean benchmark files
	rm -f $(CSV) $(CSV_SUMMARY) $(MD_SUMMARY)

# test #########################################################################

.PHONY: test test-usage test-diffpath test-diffpath-usage
test: test-diffpath test-gitignored  ## test all
test-usage: test-diffpath-usage  ## test the usage help of all programs
test-diffpath: $(OUT_diffpath)  ## test diffpath
	@file_ref=out/diffpath_c_gcc.out; \
	total_lines=$$(wc -l < "$$file_ref"); \
	for file in $^; do \
		if [[ $$(wc -l < "$$file") -eq 0 ]]; then \
			echo -e "\033[1m\033[93m$$file\033[0m: empty"; \
			continue; \
		fi; \
		N=$$(diff -U 0 "$$file_ref" "$$file" | grep -E '^\+|^-' | grep -vE '^\+\+\+|^---' | wc -l); \
		if [[ "$$N" != 0 ]]; then \
			echo -e "\033[1m\033[93m$$file\033[0m: $$N / $$total_lines mistakes"; \
			if [[ "$$N" -le 10 ]]; then \
				$(DIFFT) "$$file_ref" "$$file"; \
			fi; \
		fi; \
	done
test-gitignored: test-gitignored-stdout test-gitignored-stderr  ## test gitignored
test-gitignored-stdout: $(OUT_gitignored)  ## test gitignored stdout
	@file_ref=out/gitignored_py_python.out; \
	total_lines=$$(wc -l < "$$file_ref"); \
	for file in $^; do \
		if [[ $$(wc -l < "$$file") -eq 0 ]]; then \
			echo -e "\033[1m\033[93m$$file\033[0m: empty"; \
			continue; \
		fi; \
		N=$$(diff -U 0 "$$file_ref" "$$file" | grep -E '^\+|^-' | grep -vE '^\+\+\+|^---' | wc -l); \
		if [[ "$$N" != 0 ]]; then \
			echo -e "\033[1m\033[93m$$file\033[0m: $$N / $$total_lines mistakes"; \
			if [[ "$$N" -le 10 ]]; then \
				$(DIFFT) "$$file_ref" "$$file"; \
			fi; \
		fi; \
	done
test-gitignored-stderr: $(ERR_gitignored)  ## test gitignored stderr to be empty apart from logging
	@for file in $^; do \
		if [[ $$(grep -v -E '^(gitignored DEBUG: |gitignored INFO: |$$)' "$$file" | wc -l) -ne 0 ]]; then \
			echo -e "\033[1m\033[93m$$file\033[0m: not empty"; \
		fi; \
	done
test-diffpath-usage: $(BIN_diffpath)  ## test the usage help of all diffpath programs
	@for bin in $^; do \
		actual_output=$$($$bin --help 2>&1 >/dev/null); \
		expected_output="Usage: $$bin PATH1 PATH2"; \
		if [ "$$actual_output" != "$$expected_output" ]; then \
			echo "Unexpected usage string from $$bin:"; \
			echo "$$actual_output"; \
		fi \
	done

# misc #########################################################################

.PHONY: build update update-devbox update-pixi size list_link clean Clean help
build: $(INCLUDEFILE)  ## prepare environments using nix & devbox (should be triggered automatically)
# this file is solely here for CI cache
# it is possible the lock files between this and those under envs are out of sync
# make update should be run to ensure they are in sync
devbox.json: $(DEVBOXS_JSON)
	util/devbox_concat.py $^ > $@
$(INCLUDEFILE): util/env.sh devbox.json $(DEVBOXS)
	$< $@
update: update-devbox update-pixi  ## update environments
update-devbox:  ## update environments using nix & devbox
	devbox update --all-projects --sync-lock
update-pixi:  ## update pixi environments
	find -name pixi.toml -exec pixi update --manifest-path {} \;
size:  ## show binary sizes
	@for program in $(PROGRAMS); do \
		printf '%.0s—' {1..80}; echo; \
		find bin -mindepth 1 -maxdepth 1 -name "$${program}*" -exec du -sh --apparent-size {} + | sort -h; \
	done
list_link:  ## list dynamically linked libraries
ifeq ($(UNAME),Darwin)
	find bin -type f -executable -exec otool -L {} +;
else
	find bin -type f -executable -exec ldd {} + || true;
endif
clean: \
	clean_compile \
	clean_run \
	clean_bench \
	## clean all
	rm -f $(INCLUDEFILE) bin/.DS_Store out/.DS_Store
	rm -rf bin/*.dist
	ls bin out 2>/dev/null || true
	rm -rf bin out
gc:  ## garbage collect devbox
	find . -type f -name devbox.json -exec bash -c 'cd $${1%/*} && devbox run -- nix store gc --extra-experimental-features nix-command' _ {} \;
Clean: clean Clean_ts Clean_jl gc  ## Clean the environments too (this triggers redownload & rebuild next time!)
	find envs -type d -name '.devbox' -exec rm -rf {} +
# modified from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:  ## print this help message
	@awk 'BEGIN{w=0;n=0}{while(match($$0,/\\$$/)){sub(/\\$$/,"");getline nextLine;$$0=$$0 nextLine}if(/^[[:alnum:]_-]+:.*##.*$$/){n++;split($$0,cols[n],":.*##");l=length(cols[n][1]);if(w<l)w=l}}END{for(i=1;i<=n;i++)printf"\033[1m\033[93m%-*s\033[0m%s\n",w+1,cols[i][1]":",cols[i][2]}' $(MAKEFILE_LIST)
print-%:
	$(info $* = $($*))
