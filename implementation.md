# Demoscene Missile Command — Implementation Documentation

A hardware implementation of the classic Missile Command arcade game, written in Verilog for the [Tiny Tapeout](https://tinytapeout.com/) ASIC platform. The design outputs VGA video at 640×480 and accepts input from an SNES gamepad via PMOD.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Module Hierarchy](#2-module-hierarchy)
3. [Top-Level Module: `tt_um_ds_missile_command`](#3-top-level-module-tt_um_ds_missile_command)
4. [VGA Timing: `hvsync_generator`](#4-vga-timing-hvsync_generator)
5. [Gamepad Interface](#5-gamepad-interface)
6. [Game Objects](#6-game-objects)
   - 6.1 [Crosshair](#61-crosshair)
   - 6.2 [Fortress](#62-fortress)
   - 6.3 [Missile Starter](#63-missile_starter)
   - 6.4 [Missile](#64-missile)
   - 6.5 [Explosion](#65-explosion)
7. [Banner / Text Rendering](#7-banner--text-rendering)
   - 7.1 [Start Banner](#71-start_banner)
   - 7.2 [Game Over Banner](#72-game_over_banner)
   - 7.3 [Level Banner](#73-level_banner)
8. [Game State Machine](#8-game-state-machine)
9. [Rendering Pipeline & Color Priority](#9-rendering-pipeline--color-priority)
10. [Timing & Clock Domains](#10-timing--clock-domains)
11. [Color Encoding](#11-color-encoding)
12. [IO Pinout](#12-io-pinout)
13. [Build Configuration](#13-build-configuration)

---

## 1. Project Overview

| Property | Value |
|---|---|
| Platform | Tiny Tapeout (sky130 PDK) |
| Clock | 50 MHz (20 ns period) |
| Video Output | VGA 640×480 @ 60 Hz (2-bit-per-channel RGB) |
| Input | SNES gamepad via PMOD (serial shift-register protocol) |
| Target Density | 80 % |
| Top Module | `tt_um_ds_missile_command` |

The game runs entirely in digital logic with no CPU or ROM. All game state, sprite rendering, and game-over logic are implemented as synthesisable RTL.

---

## 2. Module Hierarchy

```
tt_um_ds_missile_command          (src/project.v)
├── hvsync_generator              (src/hsync_generator.v)
├── gamepad_pmod_single           (src/gamepad_pmod_single.v)
│   ├── gamepad_pmod_driver       (src/gamepad_pmod_driver.v)
│   └── gamepad_pmod_decoder      (src/gamepad_pmod_decoder.v)
├── explosion  ×4  (exp_0…exp_3)  (src/explossion.v)
├── missile_starter               (src/missile_starter.v)
├── missile    ×3  (m_0…m_2)      (src/missile.v)
├── crosshair                     (src/crosshair.v)
├── start_banner                  (src/start_banner.v)
├── game_over_banner              (src/game_over_banner.v)
├── level_banner                  (src/level_banner.v)
└── fortress                      (src/fortress.v)
```

---

## 3. Top-Level Module: `tt_um_ds_missile_command`

**Source:** [`src/project.v`](src/project.v)

### 3.1 Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `ui_in` | in | 8 | General-purpose inputs (gamepad PMOD lines on [6:4]) |
| `uo_out` | out | 8 | VGA output: `{hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}` |
| `uio_in` | in | 8 | Bidirectional IOs (unused) |
| `uio_out` | out | 8 | Forced 0 |
| `uio_oe` | out | 8 | Forced 0 (all inputs) |
| `ena` | in | 1 | Power enable (unused in logic) |
| `clk` | in | 1 | 50 MHz system clock |
| `rst_n` | in | 1 | Active-low synchronous reset |

### 3.2 Key Internal Signals

#### Game State

| Signal | Width | Description |
|---|---|---|
| `level` | 4-bit reg | Current level (0–8; wraps back to 0 after level 8) |
| `impacts` | 2-bit reg | Fortress remaining hits (3=full, 0=destroyed) |
| `game_over` | 1-bit reg | Set when `impacts` reaches 0 |
| `start_game_pending` | 1-bit reg | Triggers first missile salvo when game starts |
| `level_launches` | 5-bit reg | Missiles launched in the current level (0–9) |
| `missile_lines_delay` | 8-bit reg | Missile speed control (higher = slower; decreases each level) |

#### Player Input / Crosshair

| Signal | Width | Description |
|---|---|---|
| `crosshair_x`, `crosshair_y` | 10-bit reg | Crosshair screen position |
| `crosshair_active` | 1-bit reg | Whether the crosshair is rendered |
| `inp_a_prev`, `inp_start_prev` | 1-bit reg | Previous-frame edge detection for buttons |
| `fire_pulse` | 1-bit reg | Single-cycle pulse generated on A press |

#### Missiles

| Signal | Width | Description |
|---|---|---|
| `missile_fire[2:0]` | 3-bit reg | Per-missile fire strobe |
| `missile_fire_pulse` | 4-bit reg | Counts down the 4-cycle fire pulse duration |
| `missiles_in_flight` | 2-bit reg | Free-running counter used as a pseudo-random missile count (1–3) |
| `missile_start_x[0:2]` | 10-bit reg ×3 | Launch X position for each missile |
| `missile_coeff_x[0:2]` | 4-bit reg ×3 | X velocity coefficient |
| `missile_coeff_y[0:2]` | 4-bit reg ×3 | Y velocity coefficient |
| `missile_active[2:0]` | 3-bit wire | Active flag from each missile module |
| `missile_flying[2:0]` | 3-bit wire | In-flight flag from each missile module |

### 3.3 Game Parameters

| Constant | Value | Description |
|---|---|---|
| `MISSILES_PER_LEVEL` | 10 | Missiles launched before advancing a level |
| `LEVEL_DELAY_STEP` | 24 | Amount subtracted from `missile_lines_delay` per level (faster missiles) |
| `FRAMES_CROSSHAIR_DELAY` | `16'h0100` (256) | Crosshair movement rate limiter |
| `EXPLOSION_COUNT` | 4 | Simultaneous explosions supported |

### 3.4 Color Constants (6-bit `RRGGBB`, 2 bits per channel)

| Constant | Value | Color |
|---|---|---|
| `CROSSHAIR_RGB_COLOR` | `6'b00_1100` | Green |
| `FORTRESS_RGB_COLOR` | `6'b01_0101` | Magenta |
| `EXPLOSSION_RGB_COLOR` | `6'b11_1111` | White |
| `MISSILE_RGB_COLOR` | `6'b00_1100` | Cyan |
| `START_BANNER_RGB_COLOR` | `6'b00_1100` | Green |
| `GAME_OVER_BANNER_RGB_COLOR` | `6'b11_0000` | Red |

### 3.5 Game Logic Clocks

The main `always` block runs on `posedge hsync` (≈15.75 kHz), which fires once per scanline. This drives:

- Missile fire-pulse countdown
- Crosshair movement (further gated by a 256-count delay counter)
- START / fire button edge detection
- Fortress impact counting and game-over detection
- Missile salvo launch sequencing

### 3.6 Missile Launch Sequencing

```
On start_game_pending OR all missiles gone (missiles_gone edge):
  missiles_in_flight++ (mod 3, gives 1–3 pseudo-randomly)
  level_launches += missiles_in_flight

  if level_launches >= MISSILES_PER_LEVEL:
    level_launches = 0
    missile_lines_delay -= LEVEL_DELAY_STEP  ← missiles faster
    impacts = 3                              ← fortress repaired
    level++
    if level > 8: level=0, missile_lines_delay=8'hFF  ← wrap

  Always fire missile 0  at  starter_x
  If missiles_in_flight >= 2: fire missile 1 at starter_x + 120
  If missiles_in_flight == 3: fire missile 2 at starter_x + 320
```

---

## 4. VGA Timing: `hvsync_generator`

**Source:** [`src/hsync_generator.v`](src/hsync_generator.v)

Generates standard VGA 640×480 @ 60 Hz sync signals from a 50 MHz pixel clock.

### 4.1 Horizontal Timing (one scanline = 800 clocks)

```
|←── 640 visible ──→|← 16 →|←── 96 ──→|← 48 →|
       Active           FP      SYNC       BP
        hpos < 640    656…751 (SYNC active low)
```

| Parameter | Value | Description |
|---|---|---|
| `H_DISPLAY` | 640 | Visible pixels |
| `H_FRONT` | 16 | Front porch |
| `H_SYNC` | 96 | Sync pulse |
| `H_BACK` | 48 | Back porch |
| `H_MAX` | 799 | Total horizontal period − 1 |

### 4.2 Vertical Timing (one frame = 525 lines)

```
|←── 480 visible ──→|← 10 →|← 2 →|← 33 →|
      Active           BP    SYNC    FP
```

| Parameter | Value | Description |
|---|---|---|
| `V_DISPLAY` | 480 | Visible lines |
| `V_BOTTOM` | 10 | Bottom border |
| `V_SYNC` | 2 | Sync pulse |
| `V_TOP` | 33 | Top border |
| `V_MAX` | 524 | Total vertical period − 1 |

### 4.3 Outputs

| Output | Description |
|---|---|
| `hsync` | Active-low horizontal sync pulse |
| `vsync` | Active-low vertical sync pulse |
| `display_on` | High when `hpos < 640 && vpos < 480` |
| `hpos[9:0]` | Current horizontal pixel (0–799) |
| `vpos[9:0]` | Current vertical line (0–524) |

---

## 5. Gamepad Interface

### 5.1 `gamepad_pmod_single`

**Source:** [`src/gamepad_pmod_single.v`](src/gamepad_pmod_single.v)

Wrapper that instantiates the driver and decoder as a single convenient block.

### 5.2 `gamepad_pmod_driver`

**Source:** [`src/gamepad_pmod_driver.v`](src/gamepad_pmod_driver.v)

Implements the SNES serial shift-register protocol:

1. **2-stage synchroniser** on every PMOD input (`pmod_data`, `pmod_clk`, `pmod_latch`) to eliminate metastability.
2. **Shift in** one bit on every **rising edge** of `pmod_clk`: `shift_reg ← {shift_reg[10:0], pmod_data}`.
3. **Latch** `shift_reg → data_reg` on every **rising edge** of `pmod_latch` (end of 12-bit frame).

Default bus state when no gamepad is connected: all-1s (`12'hFFF`).

### 5.3 `gamepad_pmod_decoder`

**Source:** [`src/gamepad_pmod_decoder.v`](src/gamepad_pmod_decoder.v)

Decodes the 12-bit shift-register value into named button signals.

| Bit | Button |
|---|---|
| 11 | B |
| 10 | Y |
| 9 | SELECT |
| 8 | START |
| 7 | UP |
| 6 | DOWN |
| 5 | LEFT |
| 4 | RIGHT |
| 3 | A |
| 2 | X |
| 1 | L |
| 0 | R |

If `data_reg == 12'hFFF` (no gamepad), all outputs are forced to 0. `is_present` is high when a gamepad is detected.

---

## 6. Game Objects

### 6.1 Crosshair

**Source:** [`src/crosshair.v`](src/crosshair.v)

A 10×10 pixel sprite rendered at `(pos_x, pos_y)` using a hard-coded bitmap.

**Bitmap pattern** (1 = lit pixel, 10 columns × 10 rows):

```
Col →  0 1 2 3 4 5 6 7 8 9
Row 0: 0 0 0 0 0 0 0 0 1 1
Row 1: 0 0 0 0 0 0 0 0 1 1
Row 2: 0 0 0 0 0 0 0 0 1 1
Row 3: 0 0 0 0 0 0 0 0 1 1
Row 4: 0 0 0 0 0 0 0 0 1 1
Row 5: 0 0 0 0 0 0 0 0 1 1
Row 6: 0 0 0 0 0 0 0 0 1 1
Row 7: 0 0 0 0 0 0 0 0 1 1
Row 8: 1 1 1 1 1 1 1 1 1 1
Row 9: 1 1 1 1 1 1 1 1 1 1
```

The crosshair forms an L-shape (lower-right quadrant of the target area): two-pixel-wide vertical bar on the right and two-pixel-wide horizontal bar on the bottom. The player positions this over an incoming missile and presses A to fire an explosion.

Movement is driven in the top-level `always @(posedge hsync)` block:
- Step size: **3 pixels** per trigger
- Rate limiter: `counter` increments while button is held; crosshair moves only when `counter` overflows `FRAMES_CROSSHAIR_DELAY` (256 lines)
- Bounds: `x ∈ [1, 640]`, `y ∈ [1, 480]`

---

### 6.2 Fortress

**Source:** [`src/fortress.v`](src/fortress.v)

The player's base rendered as up to three rectangular blocks at the bottom of the screen, centred at x=320.

| `remaining_hits` | Blocks shown | Description |
|---|---|---|
| 3 | Left + Centre + Right | Full fortress |
| 2 | Centre + Right | Left block destroyed |
| 1 | Centre only | Only centre block remains |
| 0 | None | Fortress destroyed; game over triggered |

**Block geometry** (all coordinates relative to screen centre = 320):

```
Left block:   x ∈ [248, 296],  y ∈ [456, 480]
Centre block: x ∈ [296, 344],  y ∈ [432, 480]
Right block:  x ∈ [344, 392],  y ∈ [456, 480]
```

(`FORTRESS_BLOCK_MID_WIDTH = 24`, `FORTRESS_BLOCK_MID_HEIGHT = 12`)

---

### 6.3 `missile_starter`

**Source:** [`src/missile_starter.v`](src/missile_starter.v)

Acts as a **pseudo-random trajectory generator**. A free-running 10-bit counter (`my_x`, 0–640) increments every clock. The current counter value is divided into 7 horizontal zones, each with a pre-defined velocity coefficient pair.

| X zone | `coefficient_x` | `coefficient_y` | Direction |
|---|---|---|---|
| 0 – 80 | 2 | 3 | Far-left diagonal |
| 81 – 160 | 1 | 2 | Left diagonal |
| 161 – 240 | 1 | 3 | Shallow left |
| 241 – 400 | 0 | 2 | Straight down |
| 401 – 480 | 1 | 3 | Shallow right |
| 481 – 560 | 1 | 2 | Right diagonal |
| 561 – 640 | 2 | 3 | Far-right diagonal |

The top-level snaps `start_x` and the coefficients at launch time, providing varied but deterministic trajectories depending on when the previous salvo ended.

---

### 6.4 `missile`

**Source:** [`src/missile.v`](src/missile.v)

Each of the three missile instances manages its own trajectory and renders a pixel-thin line from its launch point to the current tip.

#### Ports Summary

| Port | Direction | Width | Description |
|---|---|---|---|
| `frames_clk` | in | 1 | = `vsync` (~60 Hz); drives position update |
| `lines_clk` | in | 1 | = `hsync` (~15.75 kHz); drives motion counter |
| `initial_x` | in | 10 | Launch X position |
| `coefficient_x/y` | in | 4 | Velocity (pixels per position update) |
| `x`, `y` | in | 10 | Current render pixel |
| `fire` | in | 1 | Launch strobe |
| `R_next/G_next/B_next` | in | 2 | Color of pixel at (x,y) in previous stage |
| `Lines_Delay` | in | 16 | Inter-step delay = `missile_lines_delay << 2` |
| `active` | out | 1 | Missile is active (either flying or visible) |
| `in_flight` | out | 1 | Currently moving |
| `impact` | out | 1 | Fortress was hit |
| `R/G/B` | out | 2 | Output pixel color |

#### Trajectory Math

The missile travels from `(init_x, 0)` toward the screen bottom. Its **line equation** is:

```
  y / dx  ==  coeff_y / coeff_x
  ⟹  y * coeff_x  ==  dx * coeff_y      (integer, no division)

  where dx = current_pixel_x - init_x
```

A pixel `(px, py)` lies on the missile trail if:

```
  |py * coeff_x  −  dx * coeff_y|  ≤  LINE_THICKNESS * 2    (LINE_THICKNESS = 2)
```

#### Motion State Machine

```
IDLE ──fire──► FLYING
                 │
           frames_counter >= Lines_Delay
                 │
           current_y += coeff_y
           current_x ±= coeff_x
                 │
         ┌───────┴────────────┐
       y≥480              collision with
     or OOB               fortress pixel
         │                    │
       IDLE          impact=1, IDLE
```

#### Collision Detection

On every pixel clock, the missile module samples `R_next/G_next/B_next` (the color that would have been rendered at `(x,y)` by earlier pipeline stages). If those bits match `Explosion_RGBColor`, the missile is absorbed without an impact. If they match `Fortress_RGBColor`, the missile registers an impact and stops. This cross-stage color comparison is the primary collision mechanism.

---

### 6.5 `explosion`

**Source:** [`src/explossion.v`](src/explossion.v)

Four explosion instances are chained so they fire in sequence, preventing overlap. Each has a unique **bitmask** (`my_number = 16'b0001 / 0010 / 0100 / 1000`).

#### Triggering Chain

```
exp_0: fires when fire=1
exp_1: fires when exp_0's control bit is clear AND fire=1
exp_2: fires when exp_1's control bit is clear AND fire=1
exp_3: fires when exp_2's control bit is clear AND fire=1
```

The `control` bus fed to each explosion is the top-level `explosions` register, which tracks which instances are currently active.

#### Animation

The explosion renders as an expanding then shrinking diamond/circle shape. It has **6 animation steps** in each direction, using a 2400-line (`16'h0960`) frame delay between steps.

| Step | `half_size` | `cut_size` | Visual radius |
|---|---|---|---|
| 0 | 2 | 1 | Tiny |
| 1 | 6 | 2 | Small |
| 2 | 10 | 3 | Medium-small |
| 3 | 14 | 4 | Medium |
| 4 | 18 | 5 | Large |
| 5 | 24 | 6 | Full |

After reaching step 5, the explosion shrinks back through the same steps to 0, then becomes inactive.

#### Render Condition

```
  active  ⟺  explode=1
          AND  |dx| < half_size
          AND  |dy| < half_size
          AND  |dx| < (half_size − cut_size)
```

This creates a diamond outline effect.

---

## 7. Banner / Text Rendering

All banners use the same rendering approach:
1. A hard-coded bitmap array (N-row × M-bit).
2. A configurable **pixel scale** (`PIXEL_WIDTH_SHIFT` and `PIXEL_HEIGHT_SHIFT`) applied as right-shifts on the coordinate, effectively enlarging each pixel by `2^shift`.
3. A `paint_banner` enable input; when low, the module outputs `active=0`.

### 7.1 `start_banner`

**Source:** [`src/start_banner.v`](src/start_banner.v)  
**Text:** "MISSILE COMMAND"  
**Bitmap:** 9 rows × 41 columns → rendered at 4× width, 2× height = **164 × 18 pixels**  
**Position:** centred at `(320, 240)` (screen centre)  
**Color:** Cyan (`START_BANNER_RGB_COLOR`)  
**Enabled when:** `impacts == 0 && !game_over`

### 7.2 `game_over_banner`

**Source:** [`src/game_over_banner.v`](src/game_over_banner.v)  
**Text:** "GAME OVER"  
**Bitmap:** 9 rows × 37 columns → rendered at 4× width, 2× height = **148 × 18 pixels**  
**Position:** centred at `(320, 240)` (screen centre)  
**Color:** Red (`GAME_OVER_BANNER_RGB_COLOR`)  
**Enabled when:** `game_over == 1`

### 7.3 `level_banner`

**Source:** [`src/level_banner.v`](src/level_banner.v)  
**Text:** "LEVEL: N" (N = current level digit, 0–8)  
**Bitmap:** 16 rows × 64 columns → rendered at 2× width, 2× height = **128 × 32 pixels**  
**Position:** `(80, 30)` (upper-left area)  
**Color:** Red (reuses `GAME_OVER_BANNER_RGB_COLOR`)  
**Enabled:** always (`paint_banner = 1'b1`) during active gameplay

The level digit is dynamically selected from a packed sub-region of the bitmap:

```
Columns 0–22: Fixed "LEVEL:" text
Columns 23–26: Level digit selected by:
    bitmap_index = 40 − (level × 4 + (col − 23))
```

---

## 8. Game State Machine

```
              ┌──────────────────────────────────────────────┐
              │                  RESET                        │
              │  impacts=0, game_over=0, level=0             │
              └────────────────────┬─────────────────────────┘
                                   │
                                   ▼
                        ┌──────────────────┐
                        │   START SCREEN    │◄──────────────────┐
                        │  impacts=0        │                    │
                        │  show: "MISSILE   │                    │
                        │        COMMAND"   │                    │
                        └────────┬─────────┘                    │
                                 │ START pressed                 │
                                 ▼                               │
                        ┌──────────────────┐                    │
                        │   ACTIVE GAME     │                    │
                        │  impacts=3        │                    │
                        │  show: level      │                    │
                        │        banner,    │                    │
                        │        fortress,  │                    │
                        │        missiles,  │                    │
                        │        crosshair  │                    │
                        └────────┬─────────┘                    │
                         ┌───────┴──────────────────┐           │
                         │ missile hits fortress     │           │
                         ▼                           ▼           │
                ┌────────────────┐       ┌────────────────────┐ │
                │ impacts 3→2→1  │       │   GAME OVER         │ │
                │ fortress shrinks│      │  game_over=1        │ │
                └────────┬───────┘       │  show: "GAME OVER"  │ │
                         │               └────────┬────────────┘ │
                         │ impacts → 0             │ START pressed │
                         └────────────────────────►──────────────┘
```

### Level Progression

```
For each missile salvo:
  missiles_in_flight ∈ {1, 2, 3}  (free-running counter, pseudo-random)
  level_launches += missiles_in_flight
  if level_launches >= 10:
    level++  (wraps 8→0)
    missile_lines_delay -= 24  (missiles get faster)
    if level wrapped: missile_lines_delay = 0xFF  (reset speed)
    impacts = 3  (fortress repaired each level!)
```

---

## 9. Rendering Pipeline & Color Priority

Each pixel clock cycle, all modules compute whether they own the current pixel `(pix_x, pix_y)`. The top-level multiplexer applies priority **highest first**:

```
Priority  Source           Condition
────────  ───────────────  ──────────────────────────────────────────
  1 (highest)  Crosshair   crosshair.active == 1
  2            Explosions  exp_0.active OR exp_1.active OR exp_2.active OR exp_3.active
  3            Missiles    m_0.active OR m_1.active OR m_2.active
  4            Fortress    fortress.active == 1
  5            Level banner level_banner.active == 1
  6            Background  Solid blue (R=00, G=00, B=11)
─ special ─  Game Over    (impacts==0 && game_over)   → game_over_banner
─ special ─  Start Screen (impacts==0 && !game_over)  → start_banner
```

When `video_active = 0` (blanking), all outputs are forced to black (0,0,0).

### VGA Output Bit Mapping

The 8-bit `uo_out` bus encodes two bits per colour channel in an interleaved format:

```
uo_out[7] = hsync
uo_out[6] = B[0]  (blue LSB)
uo_out[5] = G[0]  (green LSB)
uo_out[4] = R[0]  (red LSB)
uo_out[3] = vsync
uo_out[2] = B[1]  (blue MSB)
uo_out[1] = G[1]  (green MSB)
uo_out[0] = R[1]  (red MSB)
```

---

## 10. Timing & Clock Domains

| Clock | Frequency | Period | Source | Used for |
|---|---|---|---|---|
| `clk` | 50 MHz | 20 ns | External | Pixel rendering, input sync, all `posedge clk` logic |
| `hsync` | ≈15.75 kHz | ≈63.5 µs | Derived (hvsync_generator) | Game logic, crosshair movement, missile motion counter |
| `vsync` | ≈60 Hz | ≈16.7 ms | Derived (hvsync_generator) | Missile position update (`frames_clk`) |
| `pmod_clk` | Variable | — | Gamepad hardware | Gamepad data shift-in |

### Cross-Domain Signals in `missile`

The missile module spans two clock domains:
- **`lines_clk` (hsync) domain:** motion state machine, `flying`, `current_x/y`
- **`clk` (pixel) domain:** line-hit test, collision detection, `active`, `R/G/B`

Cross-domain handshake signals `stop_request_r` and `impact_request_r` are registered in the pixel-clock domain and read by the motion domain on the next `hsync` edge.

---

## 11. Color Encoding

All colors are represented as 6-bit values `[5:0]` with 2 bits per channel:

```
Bits [5:4] = R   (00 = off, 11 = full)
Bits [3:2] = G   (00 = off, 11 = full)
Bits [1:0] = B   (00 = off, 11 = full)
```

| 6-bit value | R | G | B | Color |
|---|---|---|---|---|
| `6'b11_1111` | 3 | 3 | 3 | White (explosions) |
| `6'b11_0000` | 3 | 0 | 0 | Red (game over, level) |
| `6'b00_1100` | 0 | 3 | 0 | Cyan* (crosshair, missiles, start banner) |
| `6'b01_0101` | 1 | 1 | 1 | Magenta (fortress) |
| `6'b00_0011` | 0 | 0 | 3 | Blue (background) |

> *Note: `6'b00_1100` maps G=11, B=00 which is green, but is labelled "Cyan" in the source. The actual displayed color depends on the DAC attached to the 2-bit R/G/B outputs.

---

## 12. IO Pinout

### Inputs (`ui_in`)

| Bit | Signal | Description |
|---|---|---|
| 7–7 | — | Unused |
| 6 | `pmod_data` | Gamepad serial data line |
| 5 | `pmod_clk` | Gamepad clock line |
| 4 | `pmod_latch` | Gamepad latch line |
| 3–0 | — | Unused |

### Outputs (`uo_out`)

| Bit | Signal | Description |
|---|---|---|
| 7 | `hsync` | VGA horizontal sync (active low) |
| 6 | `B[0]` | Blue channel LSB |
| 5 | `G[0]` | Green channel LSB |
| 4 | `R[0]` | Red channel LSB |
| 3 | `vsync` | VGA vertical sync (active low) |
| 2 | `B[1]` | Blue channel MSB |
| 1 | `G[1]` | Green channel MSB |
| 0 | `R[1]` | Red channel MSB |

### Bidirectional (`uio_*`)

All forced to 0 / input direction. Not used.

---

## 13. Build Configuration

**Source:** [`src/config.json`](src/config.json)

| Parameter | Value | Description |
|---|---|---|
| `CLOCK_PORT` | `"clk"` | Clock net name for OpenLane |
| `CLOCK_PERIOD` | 20 ns | Constraint for 50 MHz operation |
| `PL_TARGET_DENSITY_PCT` | 80 | Global placement target density |
| `FP_SIZING` | `"absolute"` | Absolute die-size floorplan |
| `RUN_CTS` | 1 | Clock Tree Synthesis enabled |
| `FP_PDN_MULTILAYER` | 0 | Single-layer Power Distribution Network |
| `RUN_LINTER` | 1 | Verilog linter enabled |
| `LINTER_INCLUDE_PDK_MODELS` | 1 | Include PDK cell models in lint |
| `RUN_KLAYOUT_XOR` | 0 | KLayout XOR DRC disabled |
| `RUN_KLAYOUT_DRC` | 0 | KLayout DRC disabled |
| `DESIGN_REPAIR_BUFFER_OUTPUT_PORTS` | 0 | Output port buffering disabled |
