/*
        StrongCopy - Copy files from a directory to a stronghelp file
        © Alex Waugh 2002

        $Id: strongcopy.c,v 1.4 2002/07/15 20:35:51 ajw Exp $

        Usage: strongcopy [-v] [-o outputfile] [inputdir]

        Bugs:
        The datestamp of all files is set to 1/1/1900 when run on a non-RISC OS system
        Will not work on big-endian machines
        Makes assumtions about structure packing/alignment


    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 *** JRF: Made work solely with SCL ***

*/

#ifndef SCL
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#else
#include "unixdirs.h"
#endif
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#ifdef __riscos
#ifndef SCL
#include <unixlib/local.h>
#else
#include "getopt.h"
typedef unsigned long off_t;
char *strdup(const char *str)
{
  char *out = malloc(strlen(str)+1);
  if (out)
    strcpy(out,str);
  return out;
}
#endif
#include <kernel.h>
#include "swis.h"
#endif

#ifdef __riscos
typedef long int32_t;
#else
#include <stdint.h>
#endif

#ifdef SCL
#define DIRSEP "."
#else
#define DIRSEP "/"
#endif

struct header {
        char magic[4];
        int32_t rootblocksize;
        int32_t stronghelpversion;
        int32_t freeblock_offset;
        int32_t rootdir_offset;
        int32_t loadaddress;
        int32_t execaddress;
        int32_t size;
        int32_t flags;
        int32_t reserved;
        char name[1];
        char pad[3];
};

struct directory_block {
        char magic[4];
        int32_t size; /* Size of directory block */
        int32_t used; /* Amount within directory block that is actually used */
};

struct directory_entry {
        int32_t object_offset;
        int32_t loadaddress;
        int32_t execaddress;
        int32_t length;
        int32_t flags;
        int32_t reserved;
        /* char name[] */
};

struct data_block {
        char magic[4];
        int32_t size;
        /* char data[] */
};


#define FILEBUF_SIZE (100*1024)

#define DIRBLOCK_INCR 10*1024

char filebuf[FILEBUF_SIZE];
FILE *outputfile;
int verbose = 0;

void error(const char *fmt, ...)
{
        va_list ap;

        va_start(ap, fmt);
        vfprintf(stderr, fmt, ap);
        fprintf(stderr, "\n");
        va_end(ap);
        exit(1);
}

int add_file(const char *filename, off_t size)
{
        int file_offset;
        int copyamount;
        struct data_block block;
        FILE *inputfile;

        if (verbose) printf("Adding file %s\n", filename);

        file_offset = ftell(outputfile);
        if (file_offset == -1) error("ftell failed");
        file_offset = (file_offset + 3) & ~3; /* Word align */
        fseek(outputfile, file_offset, SEEK_SET);

        memcpy(block.magic, "DATA", 4);
        block.size = (size + sizeof(block) +3) & ~3;
        fwrite(&block, sizeof(block), 1, outputfile);

        inputfile = fopen(filename, "rb");
        if (inputfile == NULL) error("Can't open %s", filename);

        copyamount = FILEBUF_SIZE;
        if (copyamount > size) copyamount = size;
        while (size > 0) {
                fread(filebuf, copyamount, 1, inputfile);
                fwrite(filebuf, copyamount, 1, outputfile);
                size -= copyamount;
        }

        fclose(inputfile);

        return file_offset;
}

int add_dir(const char *dirname, int *dirlength)
{
        DIR *dir;
        struct dirent *dp;
        char *dirblock;
        int dirblocksize;
        int dirblockalloced = DIRBLOCK_INCR;
        struct directory_block *dirblock_header;
        int file_offset;

        if (verbose) printf("Adding directory %s\n", dirname);

        dirblock = malloc(dirblockalloced);
        if (dirblock == NULL) error("Out of memory");
        dirblocksize = sizeof(struct directory_block);

        dir = opendir(dirname);
        if (dir == NULL) error("Can't open dir %s", dirname);

        do {
                errno = 0;
                dp = readdir(dir);
                if (dp != NULL && strcmp(dp->d_name,".") != 0 && strcmp(dp->d_name,"..") != 0) {
                        struct stat statbuf;
                        char *filename;
                        struct directory_entry *entry;
                        int len, alignedlen;
                        int i;
                        char *nametouse;

                        if (dirblocksize + sizeof(struct directory_entry) + FILENAME_MAX > dirblockalloced) {
                                dirblockalloced += DIRBLOCK_INCR;
                                dirblock = realloc(dirblock, dirblockalloced);
                                if (dirblock == NULL) error("Out of memory");
                        }
                        entry = (struct directory_entry *)(dirblock + dirblocksize);
                        dirblocksize += sizeof(struct directory_entry);

                        filename = malloc(strlen(dp->d_name) + strlen(dirname) + 2);
                        if (filename == NULL) error("Out of memory");

                        strcpy(filename, dirname);
                        strcat(filename, DIRSEP);
                        strcat(filename, dp->d_name);
                        nametouse = strdup(dp->d_name);
                        if (nametouse == NULL) error("Out of memory");

                        entry->loadaddress = 0xFFFFFF00;
                        entry->execaddress = 0x00000000;
                        if (stat(filename, &statbuf) == -1) error("stat of %s failed", filename);
#ifdef SCL
                        if ((statbuf.st_mode & S_IFMT) == S_IFDIR) {
#else
                        if (S_ISDIR(statbuf.st_mode)) {
#endif
                                int length;
                                entry->flags = 0x133;
                                entry->object_offset = add_dir(filename, &length);
                                entry->length = length;
                        } else {
#ifdef __riscos
                                int attr;
                                char buffer[FILENAME_MAX + 1];
#endif
                                char *comma;
                                int filetype = 0xFFF;

                                comma = strchr(nametouse, ',');
                                if (comma) {
                                        *comma++ = '\0';
                                        filetype = strtol(comma, NULL, 16);
                                }
#ifdef __riscos
#ifdef SCL
                                strcpy(buffer, filename);
#else
                                __riscosify_std(filename, 0, buffer, FILENAME_MAX, NULL);
#endif
                                if (_swix(OS_File, _INR(0,1) | _OUTR(2,3) | _OUT(5), 17, buffer, &(entry->loadaddress), &(entry->execaddress), &attr)) error("Failed to read file info");
                                entry->flags = attr & 0x33;
#else
                                entry->loadaddress = 0xFFF00000 | (filetype << 8);
                                entry->flags = 0x033;
#endif
                                entry->object_offset = add_file(filename, statbuf.st_size);
                                entry->length = statbuf.st_size + sizeof(struct data_block);
                        }
                        entry->reserved = 0;
                        len = strlen(nametouse) + 1;
                        alignedlen = (len + 3) & ~3;
                        memcpy(dirblock + dirblocksize, nametouse, len);
                        memset(dirblock + dirblocksize + len, 0, alignedlen - len);

                        for (i = dirblocksize; i < dirblocksize + len; i++) {
                                if (dirblock[i] == '.') dirblock[i] = '/'; /* Unmunge filename */
                        }

                        dirblocksize += alignedlen;

                        free(filename);
                } else {
                        if (errno != 0) error("readdir of %s failed", dirname);
                }
        } while (dp != NULL);

        if (closedir(dir) == -1) error("Couldn't close dir %s", dirname);


        file_offset = ftell(outputfile);
        if (file_offset == -1) error("ftell failed");
        file_offset = (file_offset + 3) & ~3; /* Word align */
        fseek(outputfile, file_offset, SEEK_SET);

        dirblock_header = (struct directory_block *)dirblock;
        memcpy(dirblock_header->magic, "DIR$", 4);
        dirblock_header->size = dirblocksize;
        dirblock_header->used = dirblocksize; /* offset to first unused part of dir block ie the size of the used part of the block */
        *dirlength = dirblocksize;

        fwrite(dirblock, dirblocksize, 1, outputfile);
        free(dirblock);

        if (verbose) printf("Finished adding directory %s\n", dirname);
        return file_offset;
}

#define usage() do { \
        fprintf(stderr, "Usage: %s [-v] [-o outputfile] [inputdir]\n", argv[0]); \
        exit(1); \
} while (0);

int main(int argc, char *argv[])
{
        struct header headerblock;
        int rootdirlength;
        char optstring[] = "vo:";
        char *outfile = "Manual";
        char *indir = ".";
        int optch;

#ifdef __riscos
#ifndef SCL
        __riscosify_control |= __RISCOSIFY_FILETYPE_EXT;
#endif
#endif

        while ((optch = getopt(argc, argv, optstring)) != -1) {
                switch (optch) {
                case 'v':
                        verbose = 1;
                        break;
                case 'o':
                        outfile = optarg;
                        break;
                default:
                        usage();
                        break;
                }
        }
        if (optind < argc - 1) usage();
        if (optind < argc) indir = argv[optind];

        if (strchr(outfile, ',') == NULL) {
                char *outfilename;

                outfilename = malloc(strlen(outfile) + 5);
                if (outfilename == NULL) error("Out of memory");
                strcpy(outfilename, outfile);
#ifndef SCL
                strcat(outfilename, ",3d6");
#endif
                outfile = outfilename;
        }

        outputfile = fopen(outfile, "wb");
        if (outputfile == NULL) error("Can't open output file");
        fseek(outputfile, sizeof(struct header), SEEK_SET);

        memcpy(headerblock.magic, "HELP", 4);
        headerblock.rootblocksize = sizeof(headerblock);
        headerblock.stronghelpversion = 275;
        headerblock.freeblock_offset = -1;
        headerblock.loadaddress = 0xFFFFFF00;
        headerblock.execaddress = 0x00000000;
        headerblock.flags = 0x133;
        headerblock.reserved = 0;
        headerblock.name[0] = '$';
        headerblock.pad[0] = 0;
        headerblock.pad[1] = 0;
        headerblock.pad[2] = 0;
        headerblock.rootdir_offset = add_dir(indir, &rootdirlength);
        headerblock.size = rootdirlength;

        fseek(outputfile, 0, SEEK_SET);
        fwrite(&headerblock, sizeof(headerblock), 1, outputfile);
        if (fclose(outputfile)) error("Failed to close output file");

        return 0;
}
