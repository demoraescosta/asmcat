.PHONY: asmcat

asmcat:
	fasm asmcat.asm -s asmcat.fas
	chmod +x asmcat
