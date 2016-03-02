# Introduction #
I am providing this code as is. Some parts of project are still incomplete. But the main functions are working fine. I cut off all Windows related code, so you can get it from HGE homepage - http://hge.relishgames.com/


# Mac OS X #
This version has been ported and tested on both PowerPC and Intel architectures. Also this version has minor internal changes in textures manager, textures locking/unlocking and render targets management. I have tested this version of engine with HGE tutorials - all seems to be good.

# iOS #
iOS version is under development now. Unfinished parts of the iOS project:
  * Full support of the UI input messages

All other stuff seems to be working. If you find that something was not implemented, you can add this code to the project.

# HGE tutorials #
All samples from original hge work fine. You can find them at  tutorials/OSX and tutorials/iOS folders. **But remember:** my HGE port is based on **nibless** application architecture: application window is created by HGE library (like in Windows version). The easiest way to create a new project is to use one of the existing tutorial projects as base project.

**How to build tutorials:** guide by K.O. :)


  * Open and build hgecore\_OSX.xcodeproj or hgecore\_iOS.xcodeproj (from  src/core/OSX or src/core/iOS folder)
  * Build HGE helper library which is located at  src/helpers/hgehelp folder
  * Build ZLib from src/core/ZLIB/zlib
  * Build tutorials

# Project support #
If you want to contribute some code, make some improvements please contact me by e-mail  (A.Onofreytchuk@gmail.com)


# HGE homepage #
You can get Win32 code and community support at http://hge.relishgames.com/

**WARNING:**

BASS Audio Library is not a part of HGE and is licensed separately. It is free for non-commercial uses, but if you want to use HGE with BASS in a commercial or shareware application you must purchase BASS.
See http://www.un4seen.com for details.


P.S. Special thanks for Alex FlasH. :)