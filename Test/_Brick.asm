INCLUDE Irvine32.inc
INCLUDELIB	user32.lib

.data


.code
GameBrick PROC
	call ClrScr
	
	CALL WaitMsg

invoke ExitProcess,0 
GameBrick ENDP

END