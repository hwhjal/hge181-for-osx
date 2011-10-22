//
//  input.mm
//  hgecore_osx
//
//  Created by Andrew Pepper on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


/*
 ** Haaf's Game Engine 1.8
 ** Copyright (C) 2003-2007, Relish Games
 ** hge.relishgames.com
 **
 ** Core functions implementation: input
 */


#include "main.h"


char *KeyNames[] =
{
	"?",
	"Left Mouse Button", "Right Mouse Button", "?", "Middle Mouse Button",
	"?", "?", "?", "Backspace", "Tab", "?", "?", "?", "Enter", "?", "?",
	"Shift", "Ctrl", "Alt", "Pause", "Caps Lock", "?", "?", "?", "?", "?", "?",
	"Escape", "?", "?", "?", "?",
	"Space", "Page Up", "Page Down", "End", "Home",
	"Left Arrow", "Up Arrow", "Right Arrow", "Down Arrow",
	"?", "?", "?", "?", "Insert", "Delete", "?",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"?", "?", "?", "?", "?", "?", "?",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"Left Win", "Right Win", "Application", "?", "?",
	"NumPad 0", "NumPad 1", "NumPad 2", "NumPad 3", "NumPad 4",
	"NumPad 5", "NumPad 6", "NumPad 7", "NumPad 8", "NumPad 9",
	"Multiply", "Add", "?", "Subtract", "Decimal", "Divide",
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"Num Lock", "Scroll Lock",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"Semicolon", "Equals", "Comma", "Minus", "Period", "Slash", "Grave",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?",
	"Left bracket", "Backslash", "Right bracket", "Apostrophe",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?", "?", "?", "?", "?", "?", "?", "?",
	"?", "?", "?"
};

unsigned char		ScanKeyTable [256] =		// Table to translate Mac key codes to scan codes 
{             //  0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19
	/*0*/		 30,  31,  32,  33,  35,  34,  44,  45,  46,  47, 000,  48,  16,  17,  18,  19,  21, 000,   2,   3, 
	/*1*/		  4,   5,   7,   6,  13,  10,   8,  12,   9,  11,  27,  24,  22,  26,  23,  25,  28,  38,  36,  40, 
	/*2*/		 37,  39,  43,  51,  53,  49,  50,  52,  15,  59,  41,  14, 000,   1, 000, 000, 000, 000, 000, 000, 
	/*3*/		000, 000, 000, 000, 000, 000, 000,  55, 000,  78, 000,  69, 000, 000, 000, 000, 000, 000, 074, 000, 
	/*4*/		000, 000, 000, 000, 000, 000, 000,  76, 000, 000, 000, 000, 000, 000, 000, 000,  63,  64,  65,  61, 
	/*5*/		 66, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000,  82,  71,  73,  83,  62,  79, 
	/*6*/		 60,  81,  59,  75,  77,  80,  72, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*7*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*8*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*9*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*10*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*11*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 
	/*12*/		000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000, 000
};

int KeyMapVK [] =
{
		//  SdlI    macI    macH    SdlH    104xtH  104xtC  sdl
    30, //  0       0x00    0x1e            A       QZ_a
    31, //  1       0x01    0x1f            S       QZ_s
    32, //  2       0x02    0x20            D       QZ_d
    33, //  3       0x03    0x21            F       QZ_f
    35, //  4       0x04    0x23            H       QZ_h
    34, //  5       0x05    0x22            G       QZ_g
    44, //  6       0x06    0x2c            Z       QZ_z
    45, //  7       0x07    0x2d            X       QZ_x
    46, //  8       0x08    0x2e            C       QZ_c
    47, //  9       0x09    0x2f            V       QZ_v
    0,  //  10      0x0A    Undefined
    48, //  11      0x0B    0x30            B       QZ_b
    16, //  12      0x0C    0x10            Q       QZ_q
    17, //  13      0x0D    0x11            W       QZ_w
    18, //  14      0x0E    0x12            E       QZ_e
    19, //  15      0x0F    0x13            R       QZ_r
    21, //  16      0x10    0x15            Y       QZ_y
    20, //  17      0x11    0x14            T       QZ_t
    2,  //  18      0x12    0x02            1       QZ_1
    3,  //  19      0x13    0x03            2       QZ_2
    4,  //  20      0x14    0x04            3       QZ_3
    5,  //  21      0x15    0x05            4       QZ_4
    7,  //  22      0x16    0x07            6       QZ_6
    6,  //  23      0x17    0x06            5       QZ_5
    13, //  24      0x18    0x0d            =       QZ_EQUALS
    10, //  25      0x19    0x0a            9       QZ_9
    8,  //  26      0x1A    0x08            7       QZ_7
    12, //  27      0x1B    0x0c            -       QZ_MINUS
    9,  //  28      0x1C    0x09            8       QZ_8
    11, //  29      0x1D    0x0b            0       QZ_0
    27, //  30      0x1E    0x1b            ]       QZ_RIGHTBRACKET
    24, //  31      0x1F    0x18            O       QZ_o
    22, //  32      0x20    0x16            U       QZ_u
    26, //  33      0x21    0x1a            [       QZ_LEFTBRACKET
    23, //  34      0x22    0x17            I       QZ_i
    25, //  35      0x23    0x19            P       QZ_p
    28, //  36      0x24    0x1c            ENTER   QZ_RETURN
    38, //  37      0x25    0x26            L       QZ_l
    36, //  38      0x26    0x24            J       QZ_j
    40, //  39      0x27    0x28            '       QZ_QUOTE
    37, //  40      0x28    0x25            K       QZ_k
    39, //  41      0x29    0x27            ;       QZ_SEMICOLON
    43, //  42      0x2A    0x2b            \       QZ_BACKSLASH
    51, //  43      0x2B    0x33            ,       QZ_COMMA
    53, //  44      0x2C    0x35            /       QZ_SLASH
    49, //  45      0x2D    0x31            N       QZ_n
    50, //  46      0x2E    0x32            M       QZ_m
    52, //  47      0x2F    0x34            .       QZ_PERIOD
    15, //  48      0x30    0x0f            TAB     QZ_TAB
    57, //  49      0x31    0x39            SPACE   QZ_SPACE
    41, //  50      0x32    0x29            `       QZ_BACKQUOTE
    14, //  51      0x33    0x0e            BKSP    QZ_BACKSPACE
    0,  //  52      0x34    Undefined
    1,  //  53      0x35    0x01            ESC     QZ_ESCAPE
    0,  //  54      0x36                            QZ_RMETA
    0,  //  55      0x37                            QZ_LMETA
    42, //  56      0x38    0x2a            L SHFT  QZ_LSHIFT
    58, //  57      0x39    0x3a            CAPS    QZ_CAPSLOCK
    56, //  58      0x3A    0x38            L ALT   QZ_LALT
    29, //  59      0x3B    0x1d            L CTRL  QZ_LCTRL
    54, //  60      0x3C    0x36            R SHFT  QZ_RSHIFT
    184,//  61      0x3D    0xb8    E0,38   R ALT   QZ_RALT
    157,//  62      0x3E    0x9d    E0,1D   R CTRL  QZ_RCTRL
    0,  //  63      0x3F    Undefined
    0,  //  64      0x40    Undefined
    0,  //  65      0x41    Undefined
    0,  //  66      0x42    Undefined
    55, //  67      0x43    0x37            KP *    QZ_KP_MULTIPLY
    0,  //  68      0x44    Undefined
    78, //  69      0x45    0x4e            KP +    QZ_KP_PLUS
    0,  //  70      0x46    Undefined
    69, //  71      0x47    0x45            NUM     QZ_NUMLOCK
    0,  //  72      0x48    Undefined
    0,  //  73      0x49    Undefined
    0,  //  74      0x4A    Undefined
    181,//  75      0x4B    0xb5    E0,35   KP /    QZ_KP_DIVIDE
    152,//  76      0x4C    0x9c    E0,1C   KP EN   QZ_KP_ENTER
    0,  //  77      0x4D    undefined
    74, //  78      0x4E    0x4a            KP -    QZ_KP_MINUS
    0,  //  79      0x4F    Undefined
    0,  //  80      0x50    Undefined
    0,  //  81      0x51                            QZ_KP_EQUALS
    82, //  82      0x52    0x52            KP 0    QZ_KP0
    79, //  83      0x53    0x4f            KP 1    QZ_KP1
    80, //  84      0x54    0x50            KP 2    QZ_KP2
    81, //  85      0x55    0x51            KP 3    QZ_KP3
    75, //  86      0x56    0x4b            KP 4    QZ_KP4
    76, //  87      0x57    0x4c            KP 5    QZ_KP5
    77, //  88      0x58    0x4d            KP 6    QZ_KP6
    71, //  89      0x59    0x47            KP 7    QZ_KP7
    0,  //  90      0x5A    Undefined
    72, //  91      0x5B    0x48            KP 8    QZ_KP8
    73, //  92      0x5C    0x49            KP 9    QZ_KP9
    0,  //  93      0x5D    Undefined
    0,  //  94      0x5E    Undefined
    0,  //  95      0x5F    Undefined
    63, //  96      0x60    0x3f            F5      QZ_F5
    64, //  97      0x61    0x40            F6      QZ_F6
    65, //  98      0x62    0x41            F7      QZ_F7
    61, //  99      0x63    0x3d            F3      QZ_F3
    66, //  100     0x64    0x42            F8      QZ_F8
    67, //  101     0x65    0x43            F9      QZ_F9
    0,  //  102     0x66    Undefined
    87, //  103     0x67    0x57            F11     QZ_F11
    0,  //  104     0x68    Undefined
    183,//  105     0x69    0xb7            QZ_PRINT
    0,  //  106     0x6A    Undefined
    70, //  107     0x6B    0x46            SCROLL  QZ_SCROLLOCK
    0,  //  108     0x6C    Undefined
    68, //  109     0x6D    0x44            F10     QZ_F10
    0,  //  110     0x6E    Undefined
    88, //  111     0x6F    0x58            F12     QZ_F12
    0,  //  112     0x70    Undefined
    110,//  113     0x71    0x0                     QZ_PAUSE
    210,//  114     0x72    0xd2    E0,52   INSERT  QZ_INSERT
    199,//  115     0x73    0xc7    E0,47   HOME    QZ_HOME
    201,//  116     0x74    0xc9    E0,49   PG UP   QZ_PAGEUP
    211,//  117     0x75    0xd3    E0,53   DELETE  QZ_DELETE
    62, //  118     0x76    0x3e            F4      QZ_F4
    207,//  119     0x77    0xcf    E0,4f   END     QZ_END
    60, //  120     0x78    0x3c            F2      QZ_F2
    209,//  121     0x79    0xd1    E0,51   PG DN   QZ_PAGEDOWN
    59, //  122     0x7A    0x3b            F1      QZ_F1
    203,//  123     0x7B    0xcb    e0,4B   L ARROW QZ_LEFT
    205,//  124     0x7C    0xcd    e0,4D   R ARROW QZ_RIGHT
    208,//  125     0x7D    0xd0    E0,50   D ARROW QZ_DOWN
    200,//  126     0x7E    0xc8    E0,48   U ARROW QZ_UP
	/* completed according to http://www.libsdl.org/cgi/cvsweb.cgi/SDL12/src/video/quartz/SDL_QuartzKeys.h?rev=1.6&content-type=text/x-cvsweb-markup */
	
	/* Aditional 104 Key XP-Keyboard Scancodes from http://www.computer-engineering.org/ps2keyboard/scancodes1.html */
	/*
	 219 //          0xdb            e0,5b   L GUI   
	 220 //          0xdc            e0,5c   R GUI   
	 221 //          0xdd            e0,5d   APPS    
	 //              E0,2A,E0,37         PRNT SCRN   
	 //              E1,1D,45,E1,9D,C5   PAUSE   
	 83  //          0x53    0x53            KP .    
	 // ACPI Scan Codes                              
	 222 //          0xde            E0, 5E  Power   
	 223 //          0xdf            E0, 5F  Sleep   
	 227 //          0xe3            E0, 63  Wake    
	 // Windows Multimedia Scan Codes                                
	 153 //          0x99            E0, 19  Next Track  
	 144 //          0x90            E0, 10  Previous Track  
	 164 //          0xa4            E0, 24  Stop    
	 162 //          0xa2            E0, 22  Play/Pause  
	 160 //          0xa0            E0, 20  Mute    
	 176 //          0xb0            E0, 30  Volume Up   
	 174 //          0xae            E0, 2E  Volume Down 
	 237 //          0xed            E0, 6D  Media Select    
	 236 //          0xec            E0, 6C  E-Mail  
	 161 //          0xa1            E0, 21  Calculator  
	 235 //          0xeb            E0, 6B  My Computer 
	 229 //          0xe5            E0, 65  WWW Search  
	 178 //          0xb2            E0, 32  WWW Home    
	 234 //          0xea            E0, 6A  WWW Back    
	 233 //          0xe9            E0, 69  WWW Forward 
	 232 //          0xe8            E0, 68  WWW Stop    
	 231 //          0xe7            E0, 67  WWW Refresh 
	 230 //          0xe6            E0, 66  WWW Favorites   
	 */
};




bool CALL HGE_Impl::Input_GetEvent(hgeInputEvent *event)
{
	CInputEventList *eptr;
	
	if(queue)
	{
		eptr=queue;
		memcpy(event, &eptr->event, sizeof(hgeInputEvent));
		queue=eptr->next;
		delete eptr;
		return true;
	}
	
	return false;
}

void CALL HGE_Impl::Input_GetMousePos(float *x, float *y)
{
	*x=Xpos; *y=Ypos;
}


void CALL HGE_Impl::Input_SetMousePos(float x, float y)
{
	POINT pt;
	pt.x=(long)x; pt.y=(long)y;
//	ClientToScreen(hwnd, &pt);
//	SetCursorPos(pt.x,pt.y);
}

int CALL HGE_Impl::Input_GetMouseWheel()
{
	return Zpos;
}

bool CALL HGE_Impl::Input_IsMouseOver()
{
	return bMouseOver;
}

bool CALL HGE_Impl::Input_GetKeyState(int key)
{
	// return (hwKeyz [key] != 0);
	return (keyz[key] & 1 != 0);
	// return ((GetKeyState(key) & 0x8000) != 0);
}

bool CALL HGE_Impl::Input_KeyDown(int key)
{
	return (keyz[key] & 1) != 0;
}

bool CALL HGE_Impl::Input_KeyUp(int key)
{
	return (keyz[key] & 2) != 0;
}

char* CALL HGE_Impl::Input_GetKeyName(int key)
{
	return KeyNames[key];
}

int CALL HGE_Impl::Input_GetKey()
{
	return VKey;
}

int CALL HGE_Impl::Input_GetChar()
{
	return Char;
}

void CALL HGE_Impl::Input_SetCursor(HCURSOR cursor)
{
    m_cursor = cursor;
}

//////// Implementation ////////

void HGE_Impl::_InputInit()
{
	POINT	pt =_GetMousePos ();
	Xpos = (float)pt.x;
	Ypos = (float)pt.y;
	
	memset(&keyz, 0, sizeof(keyz));
	memset(&hwKeyz, 0, sizeof(hwKeyz));
}

void HGE_Impl::_UpdateMouse()
{
	bMouseOver=true;

	static bool s_cursorHidden = false;
	
	if (bMouseOver && bHideMouse)
	{
		if (!s_cursorHidden)
			s_cursorHidden = true;
	}
	else
	{
		if (s_cursorHidden)
			s_cursorHidden = false;
	}
}

void HGE_Impl::_BuildEvent(int type, int key, int scan, int flags, int x, int y)
{
	CInputEventList *last, *eptr=new CInputEventList;
	unsigned char kbstate[256];
	POINT pt;
	
	eptr->event.type=type;
	eptr->event.chr=0;
	pt.x=x; pt.y=y;
	
	char ch = (char) scan;
	
	// GetKeyboardState(kbstate);
	if(type==INPUT_KEYDOWN)
	{
		if((flags & HGEINP_REPEAT) == 0) keyz[key] |= 1;
		// ToAscii(key, scan, kbstate, (unsigned short *)&eptr->event.chr, 0);
		eptr->event.chr = ch;
	}
	if(type==INPUT_KEYUP)
	{
		keyz[key] |= 2;
		// ToAscii(key, scan, kbstate, (unsigned short *)&eptr->event.chr, 0);
		eptr->event.chr = ch;
	}
	if(type==INPUT_MOUSEWHEEL)
	{
		eptr->event.key=0; eptr->event.wheel=key;
		// ScreenToClient(hwnd,&pt);
	}
	else { eptr->event.key=key; eptr->event.wheel=0; }
	
	if(type==INPUT_MBUTTONDOWN)
	{
		keyz[key] |= 1;
		// SetCapture(hwnd);
		bCaptured=true;
	}
	if(type==INPUT_MBUTTONUP)
	{
		keyz[key] |= 2;
		// ReleaseCapture();
		Input_SetMousePos(Xpos, Ypos);
		pt.x=(int)Xpos; pt.y=(int)Ypos;
		bCaptured=false;
	}
	
//	if(kbstate[VK_SHIFT] & 0x80) flags|=HGEINP_SHIFT;
//	if(kbstate[VK_CONTROL] & 0x80) flags|=HGEINP_CTRL;
//	if(kbstate[VK_MENU] & 0x80) flags|=HGEINP_ALT;
//	if(kbstate[VK_CAPITAL] & 0x1) flags|=HGEINP_CAPSLOCK;
//	if(kbstate[VK_SCROLL] & 0x1) flags|=HGEINP_SCROLLLOCK;
//	if(kbstate[VK_NUMLOCK] & 0x1) flags|=HGEINP_NUMLOCK;
	eptr->event.flags=flags;
	
	if(pt.x==-1) { eptr->event.x=Xpos;eptr->event.y=Ypos; }
	else
	{
		if(pt.x<0) pt.x=0;
		if(pt.y<0) pt.y=0;
		if(pt.x>=nScreenWidth) pt.x=nScreenWidth-1;
		if(pt.y>=nScreenHeight) pt.y=nScreenHeight-1;
		
		eptr->event.x=(float)pt.x;
		eptr->event.y=(float)pt.y;
	}
	
	eptr->next=0; 
	
	if(!queue) queue=eptr;
	else
	{
		last=queue;
		while(last->next) last=last->next;
		last->next=eptr;
	}
	
	if(eptr->event.type==INPUT_KEYDOWN || eptr->event.type==INPUT_MBUTTONDOWN)
	{
		VKey=eptr->event.key;Char=eptr->event.chr;
	}
	else if(eptr->event.type==INPUT_MOUSEMOVE)
	{
		Xpos=eptr->event.x;Ypos=eptr->event.y;
	}
	else if(eptr->event.type==INPUT_MOUSEWHEEL)
	{
		Zpos+=eptr->event.wheel;
	}
}

void HGE_Impl::_ClearQueue()
{
	CInputEventList *nexteptr, *eptr=queue;
	
	memset(&keyz, 0, sizeof(keyz));
	
	while(eptr)
	{
		nexteptr=eptr->next;
		delete eptr;
		eptr=nexteptr;
	}
	
	queue=0; VKey=0; Char=0; Zpos=0;
}