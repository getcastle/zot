# zot - minimal screenshot utility

PREFIX = /usr/local

ZIG = zig
ZIGFLAGS = -O ReleaseFast
LIBS = -lc -lX11 -lpng

all: zot

zot: zot.zig
	$(ZIG) build-exe zot.zig $(ZIGFLAGS) $(LIBS)

clean:
	rm -f zot *.o *.o.d

install: all
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f zot $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/zot

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/zot

.PHONY: all clean install uninstall
