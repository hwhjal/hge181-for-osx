//
//  resource.mm
//  hgecore_osx
//
// Created by Andrew Onofreytchuk (a.onofreytchuk@gmail.com) on 5/3/10.
// Copyright 2010 Andrew Onofreytchuk. All rights reserved.
//

/*
 ** Haaf's Game Engine 1.8
 ** Copyright (C) 2003-2007, Relish Games
 ** hge.relishgames.com
 **
 */



#include "main.h"

void* CALL HGE_Impl::Resource_Load(const char *filename, DWORD *size)
{
	static char *res_err = "Can't load resource: %s";
	
	// CResourceList *resItem=res;
	char szName[_MAX_PATH];
	// char szZipName[_MAX_PATH];
	// unzFile zip;
	// unz_file_info file_info;
	// int done, i;
	void *ptr = 0;
	
	if(filename[0]=='\\' || filename[0]=='/') goto _fromfile; // skip absolute paths
	
	// Load from pack
	
//	strcpy(szName,filename);
//	strupr(szName);
//	for(i=0; szName[i]; i++) { if(szName[i]=='/') szName[i]='\\'; }
//	
//	while(resItem)
//	{
//		zip=unzOpen(resItem->filename);
//		done=unzGoToFirstFile(zip);
//		while(done==UNZ_OK)
//		{
//			unzGetCurrentFileInfo(zip, &file_info, szZipName, sizeof(szZipName), NULL, 0, NULL, 0);
//			strupr(szZipName);
//			for(i=0; szZipName[i]; i++)	{ if(szZipName[i]=='/') szZipName[i]='\\'; }
//			if(!strcmp(szName,szZipName))
//			{
//				if(unzOpenCurrentFilePassword(zip, resItem->password[0] ? resItem->password : 0) != UNZ_OK)
//				{
//					unzClose(zip);
//					sprintf(szName, res_err, filename);
//					_PostError(szName);
//					return 0;
//				}
//				
//				ptr = malloc(file_info.uncompressed_size);
//				if(!ptr)
//				{
//					unzCloseCurrentFile(zip);
//					unzClose(zip);
//					sprintf(szName, res_err, filename);
//					_PostError(szName);
//					return 0;
//				}
//				
//				if(unzReadCurrentFile(zip, ptr, file_info.uncompressed_size) < 0)
//				{
//					unzCloseCurrentFile(zip);
//					unzClose(zip);
//					free(ptr);
//					sprintf(szName, res_err, filename);
//					_PostError(szName);
//					return 0;
//				}
//				unzCloseCurrentFile(zip);
//				unzClose(zip);
//				if(size) *size=file_info.uncompressed_size;
//				return ptr;
//			}
//			
//			done=unzGoToNextFile(zip);
//		}
//		
//		unzClose(zip);
//		resItem=resItem->next;
//	}
	
	// Load from file
_fromfile:
	
	// hF = CreateFile(Resource_MakePath(filename), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_RANDOM_ACCESS, NULL);
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

