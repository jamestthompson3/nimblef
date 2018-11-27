# nimblef

Nimblef is a utility for finding files like `fd` or `find`

# Features
* Supports regular expressions
* Ignores patterns from `.gitignore`
* Smartcase search by default
* Blazingly fast &trade;

# Usage

Use `nf` to recursively search all files in the current directory. If no arguments are given, nimblef will list all files.

`nf .html` lists all `.html` files

`nf controller` lists all files with `controller` in the name
