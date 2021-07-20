1. Introduction

ExPress is a GUI wrapper for UPX (Ultimate Packer for eXecutables).
Its simple and easy to use interface helps one using UPX, especially for
many files in different folders with different need.

2. Features

Currently, ExPress has the following features:
- Multiplatform (even on platform whose executables aren't supported (yet) by UPX, well if any ;-p)
- Multiple files (directory recursion is supported)
- Drag & drop
- Organize UPX preferences
- Low memory usage (compared to some other UPX GUI)
- Multithreading of UPX processes

3. System Requirements

- Any platform supported by UPX, Lazarus & FreePascal
- About 3-8 MB of memory, depending on platform and widgetset used (this for running the GUI, more
  will be needed as you add files to it, and not including UPX processes)

4. Compilation from source

What you need:
- Lazarus >= 0.9.30, I use current trunk (at this time of writing: 1.5)
- Free Pascal >= 2.4.2, I use current trunk (at this time of writing: 3.1.1)
- Might work on Lazarus 0.9.28.2 and/or FPC 2.4.0, but no guarantee

How:
- Open the .lpi file from Lazarus and click Build button, .lrs files for forms will be generated automatically.
  If not, make a trivial change (such as moving the form) and save rebuild. I didn't distribute it because the
  format has changed since 0.9.24. Therefore, it's needed to provide backward compatibility
