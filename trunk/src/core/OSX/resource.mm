//
//  resource.mm
//  hgecore_osx
//
//  Created by Andrew Onofreytchuk on 5/3/10.
//  Copyright 2010 Andrew Onofreytchuk (a.onofreytchuk@gmail.com). All rights reserved.
//


#include "main.h"

#include <string.h>
#include <ctype.h>

#ifndef HAVE_STRUPR
char *strupr(char *str)
{
	char *s;
	
	for(s = str; *s; s++)
		*s = toupper((unsigned char)*s);
	return str;
}
#endif

char *HGE_Impl::getNextSearchResult (NSString *fileType)
{
	if (!hSearch)
		return 0;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	while (searchIndex < fileSearcher.gl_matchc)
	{
		NSError *err = 0;
		NSString *file = [[NSString alloc] initWithBytes:fileSearcher.gl_pathv[searchIndex] length:strlen(fileSearcher.gl_pathv[searchIndex]) encoding:NSASCIIStringEncoding];
		searchIndex++;
		NSDictionary *sourceDirectoryFileAttributes = [localFileManager attributesOfItemAtPath: file error:&err];			
		NSString *sourceDirectoryFileType = [sourceDirectoryFileAttributes objectForKey:NSFileType];			
		file = [file lastPathComponent];
		if ([sourceDirectoryFileType isEqualToString:fileType] == YES)
		{
			memset(szFindFileData, 0, _MAX_PATH);
			strcpy(szFindFileData, [file cStringUsingEncoding:NSASCIIStringEncoding]);
			[pool release];
			return szFindFileData;
		}
	}
	[pool release];
	return 0;
}


bool CALL HGE_Impl::Resource_AttachPack(const char *filename, const char *password)
{
	char *szName;
	CResourceList *resItem=res;
	unzFile zip;
	
	szName=Resource_MakePath(filename);
	strupr(szName);
	
	while(resItem)
	{
		if(!strcmp(szName,resItem->filename)) return false;
		resItem=resItem->next;
	}
	
	zip=unzOpen(szName);
	if(!zip) return false;
	unzClose(zip);
	
	resItem=new CResourceList;
	strcpy(resItem->filename, szName);
	if(password) strcpy(resItem->password, password);
	else resItem->password[0]=0;
	resItem->next=res;
	res=resItem;
	
	return true;
}

void CALL HGE_Impl::Resource_RemovePack(const char *filename)
{
	char *szName;
	CResourceList *resItem=res, *resPrev=0;
	
	szName=Resource_MakePath(filename);
	strupr(szName);
	
	while(resItem)
	{
		if(!strcmp(szName,resItem->filename))
		{
			if(resPrev) resPrev->next=resItem->next;
			else res=resItem->next;
			delete resItem;
			break;
		}
		
		resPrev=resItem;
		resItem=resItem->next;
	}
}

void CALL HGE_Impl::Resource_RemoveAllPacks()
{
	CResourceList *resItem=res, *resNextItem;
	
	while(resItem)
	{
		resNextItem=resItem->next;
		delete resItem;
		resItem=resNextItem;
	}
	
	res=0;
}

void* CALL HGE_Impl::Resource_Load(const char *filename, DWORD *size)
{
	static char *res_err = "Can't load resource: %s";
	
	CResourceList *resItem=res;
	char szName[_MAX_PATH];
	char szZipName[_MAX_PATH];
	unzFile zip;
	unz_file_info file_info;
	int done, i;
	void *ptr = 0;
	
	if(filename[0]=='\\' || filename[0]=='/') goto _fromfile; // skip absolute paths
	
	// Load from pack
	
	strcpy(szName,filename);
	strupr(szName);
	for(i=0; szName[i]; i++) { if(szName[i]=='/') szName[i]='\\'; }
	
	while(resItem)
	{
		zip=unzOpen(resItem->filename);
		done=unzGoToFirstFile(zip);
		while(done==UNZ_OK)
		{
			unzGetCurrentFileInfo(zip, &file_info, szZipName, sizeof(szZipName), NULL, 0, NULL, 0);
			strupr(szZipName);
			for(i=0; szZipName[i]; i++)	{ if(szZipName[i]=='/') szZipName[i]='\\'; }
			if(!strcmp(szName,szZipName))
			{
				if(unzOpenCurrentFilePassword(zip, resItem->password[0] ? resItem->password : 0) != UNZ_OK)
				{
					unzClose(zip);
					sprintf(szName, res_err, filename);
					_PostError(szName);
					return 0;
				}
				
				ptr = malloc(file_info.uncompressed_size);
				if(!ptr)
				{
					unzCloseCurrentFile(zip);
					unzClose(zip);
					sprintf(szName, res_err, filename);
					_PostError(szName);
					return 0;
				}
				
				if(unzReadCurrentFile(zip, ptr, file_info.uncompressed_size) < 0)
				{
					unzCloseCurrentFile(zip);
					unzClose(zip);
					free(ptr);
					sprintf(szName, res_err, filename);
					_PostError(szName);
					return 0;
				}
				unzCloseCurrentFile(zip);
				unzClose(zip);
				if(size) *size=file_info.uncompressed_size;
				return ptr;
			}
			
			done=unzGoToNextFile(zip);
		}
		
		unzClose(zip);
		resItem=resItem->next;
	}
	
	// Load from file
_fromfile:
	
	FILE *f = fopen (Resource_MakePath(filename), "rb");
	char *test = Resource_MakePath(filename);
	std::cout << test << std::endl;
	if(0 == f)
	{
		sprintf(szName, res_err, filename);
		_PostError(szName);
		return 0;
	}
	
	// Get file size
	long curr_pos = ftell (f), fsize = 0;
	fseek (f, 0L, SEEK_END);
	fsize = ftell (f);
	fseek (f, curr_pos, SEEK_SET);
	
	// Get memory
	ptr = malloc(fsize);
	if(!ptr)
	{
		fclose (f);
		sprintf(szName, res_err, filename);
		_PostError(szName);
		return 0;
	}
	
	if (fsize != fread (ptr, 1, fsize, f) )
	{
		fclose (f);
		free(ptr);
		sprintf(szName, res_err, filename);
		_PostError(szName);
		return 0;
	}
	
	fclose (f);
	if(size) *size = fsize;
	return ptr;
}


void CALL HGE_Impl::Resource_Free(void *res)
{
	if(res) free(res);
}


char* CALL HGE_Impl::Resource_MakePath(const char *filename)
{
	int i;
	
	if(!filename) strcpy(szTmpFilename, szAppPath);
	else if(filename[0]=='\\' || filename[0]=='/') strcpy(szTmpFilename, filename);
	else
	{
		strcpy(szTmpFilename, szAppPath);
		if(filename) strcat(szTmpFilename, filename);
	}
	
	for(i=0; szTmpFilename[i]; i++) { if(szTmpFilename[i]=='\\') szTmpFilename[i]='/'; }
	return szTmpFilename;
}

char* CALL HGE_Impl::Resource_EnumFiles(const char *wildcard)
{
	if (wildcard)
	{
		char* pattern = Resource_MakePath (wildcard);
		if (hSearch) {globfree(&fileSearcher); hSearch = false; searchIndex = 0;}
		if (glob(pattern, 0, NULL, &fileSearcher) == 0 && fileSearcher.gl_matchc > 0)
		{
			hSearch = true;
			return getNextSearchResult (NSFileTypeRegular);
		}
		else {globfree(&fileSearcher); hSearch = false; searchIndex = 0; return 0;}
	}
	else
	{
		if(!hSearch) return 0;
		
		if(searchIndex >= fileSearcher.gl_matchc)
		{
			globfree(&fileSearcher); hSearch = false; searchIndex = 0;	
			return 0;			
		}
		return getNextSearchResult (NSFileTypeRegular);
	}	
	
	return 0;
}

char* CALL HGE_Impl::Resource_EnumFolders(const char *wildcard)
{
	if (wildcard)
	{
		char* pattern = Resource_MakePath (wildcard);
		if (hSearch) {globfree(&fileSearcher); hSearch = false; searchIndex = 0;}
		if (glob(pattern, 0, NULL, &fileSearcher) == 0 && fileSearcher.gl_matchc > 0)
		{
			hSearch = true;
			return getNextSearchResult (NSFileTypeDirectory);
		}
		else {globfree(&fileSearcher); hSearch = false; searchIndex = 0; return 0;}
	}
	else
	{
		if(!hSearch) return 0;
		
		if(searchIndex >= fileSearcher.gl_matchc)
		{
			globfree(&fileSearcher); hSearch = false; searchIndex = 0;	
			return 0;			
		}
		return getNextSearchResult (NSFileTypeDirectory);
	}	
	
	return 0;
}