![version](https://img.shields.io/badge/version-17%2B-3E8B93)
![platform](https://img.shields.io/static/v1?label=platform&message=osx-64%20|%20win-32%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-xpdf)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-xpdf/total)

# 4d-plugin-xpdf
PDF tools based on [Xpdf](https://www.xpdfreader.com/opensource.html).

#### Notes

To build Xpdf without Qt dependency, open ``cmake-config.txt`` and remove the block the checks for the library. (``#--- look for Qt``). Otherwise, CMake configure fails. Note that only the ``xpdf`` tool requires Qt. For this project, we want to build ``libfofi`` ``libgoo`` ``libxpdf_objs`` ``libsplash``.

### Syntax

[miyako.github.io](https://miyako.github.io/2020/04/19/4d-plugin-xpdf.html)
