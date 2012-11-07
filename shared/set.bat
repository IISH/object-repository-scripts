Rem capturing a return value from an application is not that easy in Windows.
Rem We use the most simple method here: running the command and capture the output on a file.
Rem Should use Powershell really...

set file=%temp%\%identifier%
set key=%1
%2 %3 %4 %5 %6 %7 %8 %9 %10> %file%.1
php %scripts%\shared\wrapper.php -i %file%.1 > %file%.2
set /p %key%=<%file%.2
del %file%.*