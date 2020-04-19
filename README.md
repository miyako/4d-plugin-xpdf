# 4d-plugin-xpdf
Xpdf

#### Notes

To build Xpdf without Qt dependency, open ``cmake-config.txt`` and remove the block the checks for the library. (``#--- look for Qt``). Otherwise, CMake configure fails. Note that only the ``xpdf`` tool requires Qt. For this project, we want to build ``libfofi`` ``libgoo`` ``libxpdf_objs``.
