#perl rfcsplitter.pl
# echo Compiling StrongCopy
# gcc strongcopy.c -o strongcopy
echo Cleaning construction directories
rm -rf sh
rm -rf shdraft
echo Building RFCs StrongHelp
perl makerfcsh.pl
echo Building Drafts StrongHelp
perl scandrafts.pl
echo Building Media types StrongHelp
perl scanmedia.pl
echo Creating Manual files
./strongcopy -o Manuals/RFCs,3d6 sh
./strongcopy -o Manuals/InetDrafts,3d6 shdraft
./strongcopy -o Manuals/MIMETypes,3d6 shmedia
