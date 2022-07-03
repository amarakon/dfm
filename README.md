DFM – dmenu File Manager
================

## Contents

-   [Introduction](#introduction)
-   [Usage](#usage)
    -   [Backtrack](#backtrack)
-   [Dependencies](#dependencies)
-   [Installation](#installation)
    -   [Universal](#universal)
    -   [Gentoo](#gentoo)
-   [Uninstallation](#uninstallation)
    -   [Universal](#universal-1)
    -   [Gentoo](#gentoo-1)
-   [Credit](#credit)

## Introduction

![](preview.gif)

DFM is a simple file manager that uses dmenu. Instead of opening a slow
graphical environment, you open dmenu and quickly choose whatever file
you want to manipulate. It supports multiple selections and wildcards.
DFM is the fastest file manager because it is only usable with the
keyboard. Please submit an issue or a pull request if you do want any
changes.

## Usage

``` sh
`# user` dfm --raw # Print the raw output of the selection
`# user` dfm --copy # Copy the raw output of the selection
`# user` dfm --copy-contents # Copy the contents of the selection
`# user` dfm --program # Open the appropriate program for the selection
```

The default is the `program` option.

To select one file, press the `Return` key. To use the input instead of
the selection, press `Shift+Return` (not necessary most of the time). To
select multiple files, press `Control+Return` on each selection and
press `Return` when you are finished. (This requires the
[multi-selection](https://tools.suckless.org/dmenu/patches/multi-selection/)
dmenu patch.) To select all the files, type `*`. To go to the home
directory, type `~`. To go back a directory, type `..`. To go to the `/`
directory, type `/`.

### Backtrack

A cool new feature I added is to quickly backtrack to any directory.
This allows you to type a directory you passed in the prompt to return
to it instead of constantly doing `..`. If you are in the
`/home/amarakon/.local/src/amarakon/dfm` directory, you can type
`.local` in the prompt and press `Return` to quickly backtrack to the
`/home/amarakon/.local` directory. You do not even need to type the full
name! You can type `.l` instead of `.local` for example. If there is
more than one match, it will use the closest one. For example, if I was
in the `/home/amarakon/.local/src/amarakon/dfm` directory and I chose to
return to `amarakon`, It will return me to
`/home/amarakon/.local/src/amarakon`.

## Dependencies

1.  dmenu
2.  perl (for case-insensitive matching)
3.  [sesame](https://github.com/green7ea/sesame) or xdg-utils & gtk+
    (sesame is preferred because it is faster and more reliable.)
4.  xclip (if you want to use the *copy* or *copy contents* features.)

Most of these will probably already be installed on your system, with
the exception of dmenu.

## Installation

### Universal

``` sh
`# user` git clone https://github.com/amarakon/dfm
`# user` cd dfm
`# root` make install
```

### Gentoo

``` sh
`# root` eselect repository add amarlay git https://github.com/amarakon/amarlay
`# root` emerge --sync amarlay
`# root` emerge x11-misc/dfm
```

## Uninstallation

### Universal

``` sh
`# user` cd dfm
`# root` make uninstall
```

### Gentoo

``` sh
`# root` emerge -c x11-misc/dfm
# Remove my overlay (optional)
`# root` eselect-repository remove -f amarlay
`# root` emerge --sync
```

## Credit

This project is based on
[clamiax/scripts](https://github.com/clamiax/scripts). It is based on
the `dbrowse` script.
