set key=%1
set file=%temp%\%identifier%.%key%
%2 %3 %4 %5 %6 %7 %8 %9>%file%

php %scripts%\shared\wrapper.php -i %file% -o %file%
set /p %key%=<%file%

del %file%