# Build the StrongHelp constructor

strongcopy: strongcopy.c
	gcc -O2 -o $@ $?
