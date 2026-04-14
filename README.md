![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Demoscene Missile Command for TinyTapeout

The Verilog implementation (well sort of) of the classic [Atari's Missile Command](https://atari.com/pages/missilecommand?srsltid=AfmBOoo7Ne8JxmRSx7aoGDwawJRuy56aG9UlHu7-Bxz7Az-XN5kpcaTQ) game.

<img src="./img/missile_command_tt.png" width="400">

<hr />

<img src="./img/missile_command_preview.gif" width="600" alt="Missile command preview">

Easy and fun to play, checkout the [details and required hardware](./docs/info.md) to get started, then just press start and begin the action!

You start at level 0 (see top left screen), and will see the enemy throwing missiles waves with 1 to 3 missiles at a time targetting your gray fortress (bottom center) and you have to defend it!, move the green cursor (crosshair) and press A to throw an anti-aereal defense bomb, if the missiles touches it it will get destroyed and you'll be able to pick the wrecks to study their technology XD.

Expect at least 12 missiles per level, on each level the missiles speed will increase until crazyness, if you receive 3 impacts to the fortress on the same level you lose, the impacts count will reset on every level change. When you see the GAME OVER banner press start to begin again.

Concentration, agility, determination, bravery, those are the virtues of a true warrior, got what is needed to fight? only those who date will have to honor to win the badge of glory.

<img src="./img/badge.jpg" width="600" alt="Missile command cup">

Move soldier and let's defend the homeland! 🪖 GO GO GO 🪖

Check out the Claude-generated documentation for technical details [here](implementation.md).

If you're a MS Windows user you can check out the VBA Excel bitmap generator I used for the banners and some sprites [here](./matrices_generator/MatricesGenerator.xlsm).

## Live the adventure locally

[Uri Shake's VGA Playground](https://vga-playground.com/) was used for the implementation and debugg of this project, you can either use it online or more convenientely run it locally

To use it online visit the [VGA Playground](https://vga-playground.com/), enjoy the demos available if you want to, then to add the Missile Command take any of the project.v files in there and paste the contents of the [project.v](./src/project.v), then, note the + sign to add more files (in the same line where the file names show) to any project, just copy create a file for each and every file in the [src](./src/) folder and paste its contents inside it, observe that all files must end with the .v extension

After adding all files you must see the simulation on the top-right corner of the browser window, see that you have access to the IO pints, the sound, gamepad and a reset button.

If you want to run locally to have the changes refreshed right away proceed as follows:

- Clone the VGA Playground GitHub repo from this URL: https://github.com/TinyTapeout/vga-playground
- You MUST clone the VGA Playground in the same folder of the project unless you know what you're doing, for example, if you have the demoscene-missile-command in the folder /clone/path/demoscene-missile-command after you clone the VGA Playground you also must have the /clone/path/vga-playground
- Navigate to the cloned folder: /clone/path/vga-playground and run the following commands (you must have nodeJS installed on your machine)
```bash
npm i
npm start
```
- At this ppint you must be able to navigate to http://localhost:5137 and see the same VGA Playground you see online
- Stop the VGA Playground and copy any of the folders in /clone/path/vga-playground/src/examples, and rename it to missile_command.
- Edit the index.ts file of the missile_command folder and add the following code:

```javascript
import crosshair_v from '../../../../demoscene-missile-command/src/crosshair.v?raw'
import explossion_v from '../../../../demoscene-missile-command/src/explossion.v?raw';
import fortress_v from '../../../../demoscene-missile-command/src/fortress.v?raw';
import game_over_banner_v from '../../../../demoscene-missile-command/src/game_over_banner.v?raw';
import gamepad_pmod_decoder_v from '../../../../demoscene-missile-command/src/gamepad_pmod_decoder.v?raw';
import gamepad_pmod_driver_v from '../../../../demoscene-missile-command/src/gamepad_pmod_driver.v?raw';
import gamepad_pmod_single_v from '../../../../demoscene-missile-command/src/gamepad_pmod_single.v?raw';
import hsync_generator_v from '../../../../demoscene-missile-command/src/hsync_generator.v?raw';
import level_banner_v from '../../../../demoscene-missile-command/src/level_banner.v?raw';
import missile_starter_v from '../../../../demoscene-missile-command/src/missile_starter.v?raw';
import missile_v from '../../../../demoscene-missile-command/src/missile.v?raw';
import project_v from '../../../../demoscene-missile-command/src/project.v?raw';
import random_v from '../../../../demoscene-missile-command/src/random.v?raw';
import start_banner_v from '../../../../demoscene-missile-command/src/start_banner.v?raw';
import winner_banner_v from '../../../../demoscene-missile-command/src/winner_banner.v?raw';

export const MissileCommand = {
  id: 'missilecommand',
  name: 'Missile Command',
  author: 'Diego Satizabal',
  sources: {
    'crosshair.v': crosshair_v,
    'explossion.v': explossion_v,
    'fortress.v': fortress_v,
    'game_over_banner.v': game_over_banner_v,
    'gamepad_pmod_decoder.v': gamepad_pmod_decoder_v,
    'gamepad_pmod_driver.v': gamepad_pmod_driver_v,
    'gamepad_pmod_single.v': gamepad_pmod_single_v,
    'hsync_generator.v': hsync_generator_v,
    'level_banner.v': level_banner_v,
    'missile_starter.v': missile_starter_v,
    'missile.v': missile_v,
    'project.v': project_v,
    'random.v': random_v,
    'start_banner.v': start_banner_v,
    'winner_banner.v': winner_banner_v
  },
};

```
- Edit the /src/index.ts file as follows:
```javascript
import { checkers } from './checkers';
import { conway } from './conway';
import { drop } from './drop';
import { gamepad } from './gamepad';
import { logo } from './logo';
import { music } from './music';
import { Project } from './Project';
import { rings } from './rings';
import { stripes } from './stripes';
import { MissileCommand } from './missile_command';

export const examples: Project[] = [stripes, music, rings, logo, conway, checkers, drop, gamepad, MissileCommand];
```
- Again, it's VERY IMPORTANT that you follow the same names for folders, files and objects unless you know what you're doing.
- Now you must be able to go to the /clone/path/vga-playground folder again and run:
```bash
npm start
```
and see the Playground with the Missile Command added as a project and run it, and the best part, as you go you'll see the changes reflected to test.

TODO: Add instructions to run the game in TangNano FPGA

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Set up your Verilog project

1. Add your Verilog files to the `src` folder.
2. Edit the [info.yaml](info.yaml) and update information about your project, paying special attention to the `source_files` and `top_module` properties. If you are upgrading an existing Tiny Tapeout project, check out our [online info.yaml migration tool](https://tinytapeout.github.io/tt-yaml-upgrade-tool/).
3. Edit [docs/info.md](docs/info.md) and add a description of your project.
4. Adapt the testbench to your design. See [test/README.md](test/README.md) for more information.

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Edit [this README](README.md) and explain your design, how it works, and how to test it.
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
