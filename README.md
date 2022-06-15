DFM – Dmenu File Manager
================

## Contents

-   [Usage](#usage)
-   [Dependencies](#dependencies)
-   [Installation](#installation)
    -   [Universal](#universal)
    -   [Gentoo](#gentoo)
-   [Uninstallation](#uninstallation)
    -   [Universal](#universal-1)
    -   [Gentoo](#gentoo-1)
-   [Credit](#credit)

DFM is a simple file manager that uses Dmenu. Instead of opening a slow
graphical environment, you open Dmenu and quickly choose whatever file
you want to manipulate. Unfortunately, it does not **yet** support
multi-selection.

## Usage

Use the `dfm` command to select any file. There are three options for
DFM:

1.  open the default program for the file (`-p`/`--program`)
2.  copy the contents of the file (`-c`/`--copy-file`)
3.  copy a line from the contents for the file (`-cf`/`--copy-file`)

The default is the program option.

## Dependencies

1.  Dmenu
2.  Xclip (if you want to use the *copy* or *copy file* features.)

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
