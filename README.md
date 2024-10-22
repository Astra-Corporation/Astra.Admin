<div align="center">
    <img src="https://tr.rbxcdn.com/180DAY-e4b804cb89bad124798ba1d4acc01cd6/150/150/Image/Webp/noFilter"/>
</div>
<hr/> 

Astra is a modified version of Adonis by Sceleratis with edits, patches, and more!
## Installation
### TODO: Update the section below.<br>
<br>If you get stuck, feel free to ask for assistance in our [Discord server](https://discord.gg/5XYP5B9YHB).

### Method 1: Official Roblox Model

* [Take a copy](https://www.roblox.com/library/7510622625/) of the Adonis loader model from the Roblox library

* Insert the model into Studio using the Toolbox into `ServerScriptService`

### Method 2: GitHub Releases

* Download the `rbxm` file snapshot from the [latest release](https://github.com/Astra-Corporation/Admin/releases/latest)
* Import the model file into Studio
  * Note: By default, snapshots included in releases have <a href="#debug-mode">`DebugMode`</a> enabled.

### Method 3: Filesystem

* Download the repository to your computer's file system
* Install and use a plugin like [Rojo](https://rojo.space/) to compile Adonis into a `rbxmx` file
  * If using Rojo, you can run `rojo build /path/to/adonis -o Adonis.rbxmx` to build a `rbxmx`
* Import the compiled model file into Studio
  * Note: By default, loaders compiled from the repository have <a href="#debug-mode">`DebugMode`</a> enabled. **This method compiles the _bleeding edge_ version of Adonis, which may be unstable.**

## Debug Mode

The Adonis loader provides a `DebugMode` option which will load a local copy of the `MainModule` rather than fetching the latest version. This could be useful if you want to stay on a particular version of Adonis or want to maintain a custom version for your game. Debug mode expects the `MainModule` to share the same parent with the loader model (e.g. both should be in `ServerScriptService`). **By default, snapshots provided in  releases have `DebugMode` enabled.**

### Toggling debug mode

* Open `Astra_Loader` > `Loader` > `Loader`
* Change `DebugMode` at the end of the `data` table to the desired value (e.g. `DebugMode = false`)

## Links
* Official Adonis Loader: https://www.roblox.com/library/7510622625/Adonis-Loader
* Official MainModule: https://www.roblox.com/library/7510592873/Adonis-MainModule
* Documentation: https://github.com/Astra-Corporation/Admin/wiki
* Discord Server: https://discord.gg/5XYP5B9YHB
* Plugins Repository: https://github.com/Astra-Corporation/Admin-Plugins

## Contributing

The purpose of this repository is to allow others to contribute and make improvements to Adonis. Even if you've never contributed on GitHub before, we would appreciate any contributions that you can provide.

### [Contributing Guide](https://github.com/Astra-Corporation/Admin/blob/master/CONTRIBUTING.md)

Read the [contributing guide](https://github.com/Astra-Corporation/Astra.Admin/blob/master/CONTRIBUTING.md) to get a better understanding of our development process and workflow, along with answers to common questions related to contributing to Adonis.
