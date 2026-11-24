# Log Grapple

**Nexus Mods** https://www.nexusmods.com/railroader/mods/2368

This is the source of Log Grapple 0.5.5. The ready-made zip is on the Nexus page.

Log and pulpwood loaders that keep up with your trains. A data-only mod, no DLL.

## What it does
- Every log and pulpwood loader loads at least 3,000 tons a day, the rate of the game's own fastest, Graham County
  Pulpwood. A loader that is already faster is left alone. On the base map that raises 11 loaders at Connelly Creek,
  Walker, Barker's Creek and Hemingway East. The loaders are found when the map loads, so it also works on other maps.
- At a camp, a log loader and a pulpwood loader whose tracks are built by the same milestone load on each other's
  tracks. The pairs are Connelly Creek L1 and P1, L2 and P2, L3 and P3/P4, and Walker L1 and LP1. Each keeps its own pile, and the
  car's destination picks which one loads.
- Logs may ride in gondolas, any GB type, at every log loader and unloader. How much a gondola holds depends on
  the car, from about 29 tons in a 35ft gondola to about 62 tons in a 67ft Mill gondola (a 48ft holds about 42).
  In the car the logs draw as logs, a pile of 12 that fills from the bottom row up.
- Pulpwood draws as pulpwood in every GB gondola. The game's model only fit the 40ft wood gondola, and the other four
  showed crates. In the 35ft and 48ft gondolas the pile is squashed lower to fit.
- The Scott Tie Plant unloads logs as fast as the Whittier sawmill does (36,000 tons a day, up from 1,800).
- At the Scott Tie Plant, logs and creosote unload on both tracks, and ties load and sell on both.

## Good to know
Piles and production are not changed in the main file. A fast loader can empty its pile and then wait on the camp.
Milestone-gated loaders still unlock the normal way, only their rate changes.
Gondolas are added to the game's list of log car types, never replacing it, so another mod's change to that list
survives. Logs in gondolas can also be sent to the Scott Tie Plant and any other log unloader that orders logs.
At the Scott Tie Plant a car is still served by its waybill, so an empty tie car and a loaded log car can wait on the same track.
A normal start puts two "[log-grapple]" lines in Player.log, one for the load models and one with the counts and the loader ids.
The log pile is one new load model, ashenmare/loadmodel-logs-gondola, built from the game's own log mesh and sized to fit the smallest gondola, so it is never scaled.
The pulpwood change is the model's minimum height, 1.8 m down to 1.2 m, and only from the game's own value. If another mod already changed it, it is left alone and one warning goes in Player.log.

## Production variants
The main file is 1x, production as the game has it. The optional files 2x, 3x, 4x and 5x multiply the production,
loading speed and pile size of the logging camps by that number. A full pile takes the same hours to fill, there is just more
of it. They are the same mod in the same LogGrapple folder, so use one file only.
Covered are Connelly Creek (L1, L2, L3, P1, P2, P3/P4), Walker Upper and Lower (logs and Lower pulpwood), and the
pulpwood sidings at Barker's Creek, Hemingway East and Graham County. The Scott Tie Plant and the Whittier Saw Mill
are not changed. Camps that unlock with a milestone still unlock normally.
Loading scales too, from 3,000 tons a day to 6,000 at 2x, up to 15,000 at 5x, so the camps can ship what they make.
Production runs on the host, so in multiplayer the host's file decides. To switch, unzip the other file over the
LogGrapple folder and replace the files, then load your save again.

## Compatibility
The mod never lowers a rate, so a mod that sets a higher one wins. A mod that scales loader and unloader speeds after
this one builds on the raised rates.
It needs the game's own packs rr/loads, rr/loads-models01, rr/fl-skeleton01 and rr/fb-flatcar04 and loads after them.

## Install
1. Unzip so you have a LogGrapple folder in  Documents\Railroader\Mods\
   (Linux/Proton, the same folder inside the game's Proton prefix).
   Inside should be Info.json, Scripts\Data.rl, README.txt and LICENSE.txt.
2. Main menu > Mods > Manage Mods > tick Log Grapple > Apply.

## Multiplayer
The host needs it for the faster rates. Players can join without it, but their car menus will not offer gondolas
for log industries, and they see crates where you see logs and pulpwood. Give it to everyone.

## Removing it
Nothing it changes is saved, so the loaders and the Scott Tie Plant go back to the game's own rates, and camp loaders
and the Scott Tie Plant go back to their own tracks. Gondolas still holding logs stay loaded and nothing will unload them until you turn it
back on, so unload them first.
Untick it in Manage Mods and the game asks about your saves. A save that used it shows "This Save Uses Different
Mods". Pick "Keep My Current Mods" to carry on without it. If you delete the folder instead, loading shows "Mod Not
Available". Pick "Load Without It".

## Changes
0.5.5
Added logs drawn as logs in gondolas, and pulpwood drawn as pulpwood in every gondola.
0.5.4
Added production variants 2x to 5x for the logging camps as optional files.
0.5.3
Changed the Scott Tie Plant so logs and creosote unload and ties load and sell on both of its tracks.
0.5.2
First release.

## Using this source

The mod is the `LogGrapple` folder. It is a data pack with no DLL, so there is nothing to build. Copy the folder into
`Documents/Railroader/Mods` and tick it in Manage Mods.

## License

MIT, see LICENSE.

Made with AI assistance (Claude), every release reviewed and audited in game by a human.
