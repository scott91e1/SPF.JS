\ $Id: spf_win_memory.f,v 1.11 2011/04/26 15:49:28 ruv Exp $

\ Управление памятью.
\  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
\  Ревизия - сентябрь 1999

\ 94 MEMORY

VARIABLE USER-OFFS \ смещение в области данных потока, 
                   \ где создаются новые переменные

: ERR ( 0 -- ior | x -- 0 )
;

: USER-ALLOT ( n -- )
  USER-OFFS +!

\ выровняем в USER-CREATE ~day 
\  USER-OFFS @ +   \ с начала прибавляем
\  CELL 1- +  [ CELL NEGATE ] LITERAL AND \ потом выравниваем
\  USER-OFFS !
;
: USER-HERE ( -- n )
  USER-OFFS @
;


: ALLOCATE ( u -- a-addr ior ) \ 94 MEMORY
\ Распределить u байт непрерывного пространства данных. Указатель пространства 
\ данных не изменяется этой операцией. Первоначальное содержимое выделенного 
\ участка памяти неопределено.
\ Если распределение успешно, a-addr - выровненный адрес начала распределенной 
\ области и ior ноль.
\ Если операция не прошла, a-addr не представляет правильный адрес и ior - 
\ зависящий от реализации код ввода-вывода.

\ SPF: ALLOCATE выделяет одну лишнюю ячейку перед областью данных
\ для "служебных целей" (например, хранения класса созданного объекта)
\ по умолчанию заполняется адресом тела процедуры, вызвавшей ALLOCATE
  DUP 0< IF DROP 0 -300
  ELSE
    CELL+ ALLOCATE 0=
    IF R@ OVER ! CELL+ 0 ELSE -300 THEN
  THEN
;

: FREE ( a-addr -- ior ) \ 94 MEMORY
\ Вернуть непрерывную область пространства данных, индицируемую a-addr, системе 
\ для дальнейшего распределения. a-addr должен индицировать область 
\ пространства данных, которая ранее была получена по ALLOCATE или RESIZE.
\ Указатель пространства данных не изменяется данной операцией.
\ Если операция успешна, ior ноль. Если операция не прошла, ior - зависящий от 
\ реализации код ввода-вывода.
  CELL- FREE
;

: RESIZE ( a-addr1 u -- a-addr2 ior ) \ 94 MEMORY
\ Изменить распределение непрерывного пространства данных, начинающегося с 
\ адреса a-addr1, ранее распределенного по ALLOCATE или RESIZE, на u байт.
\ u может быть больше или меньше, чем текущий размер области.
\ Указатель пространства данных не изменяется данной операцией.
\ Если операция успешна, a-addr2 - выровненный адрес начала u байт 
\ распределенной памяти и ior ноль. a-addr2 может, но не должен, быть тем же 
\ самым, что и a-addr1. Если они неодинаковы, значения, содержащиеся в области 
\ a-addr1, копируются в a-addr2 в количестве минимального из размеров этих 
\ двух областей. Если они одинаковы, значения, содержащиеся в области, 
\ сохраняются до минимального из u или первоначального размера. Если a-addr2 не 
\ тот же, что и a-addr1, область памяти по a-addr1 возвращается системе 
\ согласно операции FREE.
\ Если операция не прошла, a-addr2 равен a-addr1, область памяти a-addr1 не 
\ изменяется, и ior - зависящий от реализации код ввода-вывода.
  DUP 0< IF DROP -300
  ELSE
    CELL+ SWAP CELL- SWAP RESIZE 0=
    IF CELL+ 0 ELSE -300 THEN
  THEN
;
