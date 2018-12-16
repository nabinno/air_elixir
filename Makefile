MAKEFLAGS += --silent

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

CFLAGS  = -g -O3 -ansi -pedantic -Wall -Wextra -I$(ERLANG_PATH)
LDFLAGS = -lwiringPi

ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC
	ifeq ($(shell uname),Darwin)
		LDFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
endif

_build/c/libdht11.so:
	$(CC) $(CFLAGS) -shared -w $(LDFLAGS) -o $@ priv/c/dht11.c

clean:
	$(RM) -r _build/nifs/*

