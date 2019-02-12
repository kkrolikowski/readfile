# Readfile
> display a plain text file contents on the screen

Readfile accepts two arguments:
* file path (mandatory)
* lines (optional)
Second - optional argument represents number of lines to read
## Compilation procedure
Make sure you have installed additional tools: **yasm** assembler and **gcc** compiler
```
yasm -f elf64 main.asm -l main.lst
yasm -f elf64 core.asm -l core.lst
yasm -f elf64 file.asm -l file.lst
gcc -no-pie -o readfile main.o core.o file.o
```
## Running examples
Running program without arguments display quick help
```
shell~$ ./readfile 
readfile quick help.
If you need to display first-n lines from file specify second argument
Usage: ./readfile simple.txt [n-lines]
```
Running program with one argument
```
shell~$ ./readfile sample.txt 
Lorem Ipsum is simply dummy text of the printing and typesetting industry. 
Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley 
of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into 
electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset 
sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
```
Running program with line count argument
```
shell~$ ./readfile sample.txt 3
Lorem Ipsum is simply dummy text of the printing and typesetting industry. 
Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley 
of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into 
```