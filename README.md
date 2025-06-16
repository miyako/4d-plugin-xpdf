![version](https://img.shields.io/badge/version-17%2B-3E8B93)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-xpdf/total)

### Dependencies and Licensing

* the source code of this plugin developed using the [4D Plug-in SDK](https://github.com/4d/4D-Plugin-SDK) is licensed under the MIT license
* see [Xpdf](https://www.xpdfreader.com/opensource.html) for the licensing of **Xpdf** (shared library).
* the licensing of the binary product of this plugin is subject to the licensing of all its dependencies.
 
# 4d-plugin-xpdf
PDF tools based on [Xpdf 4.02](https://www.xpdfreader.com/opensource.html).

#### Notes

To build Xpdf without Qt dependency, open ``cmake-config.txt`` and remove the block the checks for the library. (``#--- look for Qt``). Otherwise, CMake configure fails. Note that only the ``xpdf`` tool requires Qt. For this project, we want to build ``libfofi`` ``libgoo`` ``libxpdf_objs`` ``libsplash``.

### Syntax

[miyako.github.io](https://miyako.github.io/2020/04/19/4d-plugin-xpdf.html)

### to add fontconfig

in CMake, set `CMAKE_EXE_LINKER_FLAGS`

```
"-lfontconfig -L{LIBRARY_SEARCH_PATH}"
```

generate UNIX *Makefile*

in *aconf.c*, set 

```
#define HAVE_FREETYPE_H 1
```

