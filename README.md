# **pps** Toolbox for CI direct stimulation #
**p**layer.**p**lay(**s**timulus)

This toolbox is meant to assist the design of cross-devices direct stimulation experiments in Matlab.

It is composed of:

1. Scripts to play sound uniformly across CI platforms: `player.play(stimulus)`.
Scripts are object-oriented, based on three Matlab super classes, `Player`, `Format` and `Stimulus`.
1. Demos.

Note that this toolbox has not yet passed its version `1.0.0`, meaning that a few features are missing, and/or might change significantly.
If you notice any issue, or want to suggest a feature, just report it [here](https://github.com/fguerit/pps-toolbox/issues).

## Requirements ##

* Research software from the different CI companies (hence having signed an agreement with them),
* Matlab (tested with Matlab 2014a, 2015b, 2016a),
* Python 2.7 for use with NIC3.

## How do I get set up? ##

* Download the [latest release](https://github.com/fguerit/pps-toolbox/releases/latest),
* Run `ppsToolboxStartup`,
* Check the demos in the `demos` folder.

## Where can I get help? ##

There is a `demos` folder inside the repository. You are also welcome to ask questions
on the [issue tracking page](https://github.com/fguerit/pps-toolbox/issues).

## Changelog ##

Changes can be tracked in the [changelog.md](changelog.md) file.

## Citing the toolbox ##

There is no requirement to cite this toolbox for using it (cf, [license](license)). If you want to do so, please use the following DOI:

Guérit, François, (2018). PPS Toolbox. [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1143689.svg)](https://doi.org/10.5281/zenodo.1143659)

## Acknowledgements ##

Thanks to Alexandre Chabot-Leclerc for early discussions on the object-oriented design.
Thanks to Niclas Alexander Janssen for feedback on the Cochlear interface.
