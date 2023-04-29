DFM – dmenu File Manager
================

## Contents

- [Introduction](#introduction)
- [Usage](#usage)
  - [Backtrack](#backtrack)
- [Dependencies](#dependencies)
- [Installation](#installation)
  - [Universal](#universal)
  - [Gentoo](#gentoo)
- [Uninstallation](#uninstallation)
  - [Universal](#universal-1)
  - [Gentoo](#gentoo-1)
- [Configuration](#configuration)
- [Credit](#credit)

## Introduction

DFM is a simple file manager that uses dmenu. Instead of opening a slow
graphical environment, you open dmenu and quickly choose whatever file
you want to manipulate. It supports multiple selections and wildcards.
DFM is the fastest file manager because it is only usable with the
keyboard, unless you apply the
[mouse-support](https://tools.suckless.org/dmenu/patches/mouse-support/)
dmenu patch. Keep in mind that DFM is still not a finished project,
meaning you will rarely encounter a bug. Please submit an issue or a
pull request if you have any issues or want any changes.

## Usage

``` sh
`# user` dfm --print # Print the output of the selection
`# user` dfm --copy # Copy the output of the selection to the clipboard
`# user` dfm --open # Open the appropriate program for the selection
`# user` dfm --menu=fzf # Change the menu command from `dmenu` to `fzf`
`# user` dfm --restore # Restore the location of the previous run
```

The default is the `open` option.

To select one file, press the <kbd>Return</kbd> key. To use the input
instead of the selection, press <kbd>Shift</kbd><kbd>Return</kbd> (not
necessary most of the time). To select multiple files, press
<kbd>Control</kbd><kbd>Return</kbd> on each selection and press
<kbd>Return</kbd> when you are finished. (This requires the
[multi-selection](https://tools.suckless.org/dmenu/patches/multi-selection/)
dmenu patch.) To select all the files, type `*`. To go to the home
directory, type `~`. To go back a directory, type `..` or press
<kbd>Shift</kbd><kbd>Return</kbd> without typing anything. To go to the
`/` directory, type `/`.

### Backtrack

A cool new feature I added is to quickly backtrack to any directory.
This allows you to type a directory you passed in the prompt to return
to it instead of constantly doing `..`. If you are in the
`/home/amarakon/.local/src/amarakon/dfm` directory, you can type
`.local` in the prompt and press <kbd>Return</kbd> to quickly backtrack
to the `/home/amarakon/.local` directory. You do not even need to type
the full name! You can type `.l` instead of `.local` for example. If
there is more than one match, it will use the closest one. For example,
if I was in the `/home/amarakon/.local/src/amarakon/dfm` directory and I
chose to return to `amarakon`, It will return me to
`/home/amarakon/.local/src/amarakon`.

## Dependencies

1.  dmenu
2.  perl (for case-insensitive matching)
3.  [sesame](https://github.com/green7ea/sesame) or xdg-utils (sesame is
    preferred because it supports multi-selection and it is faster.)
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

### Arch

Install the [dmenu-dfm](https://aur.archlinux.org/packages/dmenu-dfm) AUR
package.

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

### Arch

Uninstall the [dmenu-dfm](https://aur.archlinux.org/packages/dmenu-dfm) AUR
package.

### Gentoo

``` sh
`# root` emerge -c x11-misc/dfm
# Remove my overlay (optional)
`# root` eselect-repository remove -f amarlay
`# root` emerge --sync
```

## Configuration

You can change the default options for DFM via the configuration file.
The configuration file is located in the configuration directory, so
usually `~/.config/dfm/dfm.conf`. Here is an example configuration:

``` sh
copy=clipboard
cat=true
case_sensitivity=sensitive
menu=fzf
length=30
path=full
```

## Credit

This project is based on
[clamiax/scripts](https://github.com/clamiax/scripts). It is based on
the `dbrowse` script.
