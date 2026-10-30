cl /nologo /LD /EHsc /Zs zoo.cpp /d1reportAllClassLayout > classes.txt || exit /b 1
cl /nologo /LD /EHsc /O2 zoo.cpp /Fe:zoo.dll || exit /b 1
dumpbin /nologo /symbols zoo.obj > symbols.txt || exit /b 1
dumpbin /nologo /exports zoo.dll > exports.txt || exit /b 1
