SRC_C = $(wildcard src/*.c)
BIN_C = $(patsubst src/%.c, bin/%_c, $(SRC_C))
cc = gcc
ARG_C = -O3 -march=armv8.5-a -mtune=native -std=c23

c: $(BIN_C)
bin/%_c: src/%.c
	@mkdir -p $(@D)
	$(cc) -o $@ $< $(ARG_C)

clean:
	rm -rf bin
print-%:
	$(info $* = $($*))
