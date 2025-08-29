# KOReader KarMtka / Copy to Xochitl Plugin

A KOReader plugin that enables highlighted fragments of documents
to be copied over to native xochitl notebooks.

## Installation

1. Clone this repository into your plugins folder. 
If you are using toltec it should be located at 
*/home/root/.entware/koreader/plugins/*.
2. Download [binary release](https://github.com/cyanjnpr/karMtka/releases/latest) of karMtka or
[build it yourself](https://github.com/cyanjnpr/karMtka?tab=readme-ov-file#building) for your device.
3. Copy binary file to the device under the name *karmtka*.
5. If the directory in which you placed the executable is not added to the PATH, 
specify executable path from the plugin settings:
*Tools > KarMtka / Copy To Xochitl > Settings > Custom path to the karMtka executable*

## Usage

Default 'Copy' button available from the highlight menu is replaced by 'Copy to Xochitl' button.
By default it will overwrite current page in last modified notebook with selected text.

Settings are available under:
*Tools > KarMtka / Copy To Xochitl > Settings*

## Caveats

Xochitl writes changes to disk only after closing the notebook and reads from disk only after opening it.
To effectively use this plugin you must close the target notebook in xochitl before switching to KOReader to copy selection.

In case of `append` mode which adds new page to the notebook, the whole xochitl apps needs to be restarted to detect changes.
Three other modes work fine without restarting.

## Compatibility

This plugin is developed only for the reMarkable devices. It should
work on all reMarkable devices that use version 6 of lines format to store documents 
(software releases 3.X).
