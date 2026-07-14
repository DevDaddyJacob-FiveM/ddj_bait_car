# Bait Car
Turn any vehicle into a police bait car. Fit a car with the bait car gear, then
use the handheld remote to remotely kill its engine, lock the doors, flash the
lights, set off the alarm and track its location once a thief takes off in it.

Other resources can hook into a bait car through a small set of exports, so
things like engine-idle scripts know to back off the moment the operator kills
the bait car.

### Features
- **Installable gear** – a car must have the bait car gear fitted before it can
  be controlled. Gear state is stored on the vehicle and synced to everyone.
- **Handheld remote UI** – an in-game key-fob styled remote with buttons for the
  bait car's controls. Cycle between every bait car in range and see each unit's
  live status.
- **Remote controls** – a POWER toggle that kills the engine and locks the doors
  together, plus separate door locks, light flash, alarm and locate buttons.
- **Exports** – let other resources read a bait car's state (see below).

### Usage
| Action | Default |
|---|---|
| Open the remote | `F7` (or `/baitcar`) |
| Install gear on the vehicle you're in / nearest | `/baitcar install` |
| Remove gear | `/baitcar uninstall` |

The default keybind and the ranges can be changed in
[config.lua](./config.lua); the keybind itself can also be rebound in the FiveM
settings.

### Exports
Both the client and server expose the same read helpers (pass a vehicle entity
handle):

```lua
-- Is the gear installed on this vehicle?
exports["ddj_bait_car"]:isBaitCar(vehicle)

-- Has the operator remotely killed the engine? This is the signal an
-- engine-idle / "keep engine running" resource should check before it keeps a
-- bait car running.
if exports["ddj_bait_car"]:isEngineDisabled(vehicle) then
    return -- don't fight the bait car operator
end

exports["ddj_bait_car"]:areDoorsLocked(vehicle)
exports["ddj_bait_car"]:getBaitCarState(vehicle)
```

The client also exposes a helper to grab the closest bait car:

```lua
local vehicle, netId = exports["ddj_bait_car"]:getNearestBaitCar(50.0)
```

### Dependencies
- [ddj_lib](https://github.com/DevDaddyJacob-FiveM/ddj_lib)

### Installation
Installing the resource is simple, just download the latest version from the [releases](https://github.com/DevDaddyJacob-FiveM/ddj_bait_car/releases/latest) tab, place the folder into your FiveM resources folder and then add `ensure ddj_bait_car` to your server.cfg file.

### Configuration
All of the configuration and documentation for it can be found in the [config.lua](./config.lua) file.

# License
This project uses the **Mozilla Public License 2.0**
<br>
Permissions of this weak copyleft license are conditioned on making available source code of licensed files and modifications of those files under the same license (or in certain cases, one of the GNU licenses). Copyright and license notices must be preserved. Contributors provide an express grant of patent rights. However, a larger work using the licensed work may be distributed under different terms and without source code for files added in the larger work.
<br>
<br>
The license can be read [here](./LICENSE)
<br>
<br>
The following table provides a breif overview of the license. Hovering each point will provide a more detailed description.

[permissions1]: ## "The licensed material and derivatives may be used for commercial purposes."
[permissions2]: ## "The licensed material may be distributed."
[permissions3]: ## "The licensed material may be modified."
[permissions4]: ## "This license provides an express grant of patent rights from contributors."
[permissions5]: ## "The licensed material may be used and modified in private."

[conditions1]: ## "Source code must be made available when the licensed material is distributed."
[conditions2]: ## "A copy of the license and copyright notice must be included with the licensed material."
[conditions3]: ## "Modifications must be released under the same license when distributing the licensed material. In some cases a similar or related license may be used."

[limitations1]: ## "This license includes a limitation of liability."
[limitations2]: ## "This license explicitly states that it does NOT grant trademark rights, even though licenses without such a statement probably do not grant any implicit trademark rights."
[limitations3]: ## "This license explicitly states that it does NOT provide any warranty."

| Permissions | Conditions | Limitations |
|---|---|---|
| [<img src="./.github/assets/licenseSpriteGreen.png"> Commercial use][permissions1] <br> [<img src="./.github/assets/licenseSpriteGreen.png"> Distribution][permissions2] <br> [<img src="./.github/assets/licenseSpriteGreen.png"> Modification][permissions3] <br> [<img src="./.github/assets/licenseSpriteGreen.png"> Patent use][permissions4] <br> [<img src="./.github/assets/licenseSpriteGreen.png"> Private use][permissions5] | [<img src="./.github/assets/licenseSpriteBlue.png"> Disclose source][conditions1] <br> [<img src="./.github/assets/licenseSpriteBlue.png"> License and copyright notice][conditions3] <br> [<img src="./.github/assets/licenseSpriteBlue.png"> Same license (file)][conditions2] | [<img src="./.github/assets/licenseSpriteRed.png"> Liability][limitations1] <br> [<img src="./.github/assets/licenseSpriteRed.png"> Trademark use][limitations2] <br> [<img src="./.github/assets/licenseSpriteRed.png"> Warranty][limitations3] |