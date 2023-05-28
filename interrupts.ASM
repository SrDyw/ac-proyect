cli
;Modificaciones a la TVI:
	 mov	  ax,0
	 mov	  es, ax
	 mov	  ax,timer
	 mov	  [es:8*4],ax
	 mov	  [es:8*4+2],cs       ;cs siempre tiene inicialmente la direcc 7c00h
 sti
 cli

	 mov	  ax, teclado
	 mov	  [es:9*4],ax
	 mov	  [es:9*4+2],cs

 sti
 cli

	 mov	  ax,show_time
	 mov	  [es:70h*4],ax
	 mov	  [es:70h*4+2],cs

	 mov	  al,0bh		  ; Activar las interrupciones del RTC
	 out	  70h,al
	 in	  al,71h
	 or	  al,64 		  ; haciendo '1' el bit 6 del registro B
	 mov	  ah,al
	 mov	  al,0bh
	 out	  70h,al
	 mov	  al,ah 		  ; Escribir el valor modificado
	 out	  71h,al
						; Por defecto, la irq8 está deshabilitada :-(
	 in	  al,0A1h		  ; Leer la máscara de interrupciones del PIC esclavo
	 and	  al,0feh		  ; Activar la irq8 (bit0 = 0)...
	 out	  0A1h,al

 sti