# nimblef

Nimblef is a utility for finding files like `fd` or `find`

# Features
* Supports regular expressions
* Ignores patterns from `.gitignore`
* Smartcase search by default
* Blazingly fast &trade;

# Installation

You need to have the nim compiler installed on your machine. Compile with the command `nim c -d:release -o:nf nimblef.nim` from the root folder.

Add the path containing the recently compiled binary to your `$PATH`

# Usage

Use `nf` to recursively search all files in the current directory. If no arguments are given, nimblef will list all files.

`nf .html` lists all `.html` files

`nf controller` lists all files with `controller` in the name

`nf --no-ignore` lists all files without skipping those outlined in `.gitignore`
