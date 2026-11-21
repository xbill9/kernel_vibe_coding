# Galaxy Book Go: USB-C after boot (charging and devices), charge LED

Contributed by Knifethrower (2026-10-22, see [linux-arm-adventures#1](https://github.com/xbill9/linux-arm-adventures/issues/1)). Tested on one Galaxy Book Go, Wi-Fi model, Debian 13 with kernel 7.2.9 from trixie-backports and this folder's DTB chain plus `gbgo-charge`.

Without help, the USB-C ports only work for things connected at power-on: the boot firmware sets them up once. [scripts/gbgo-usbc-power](scripts/gbgo-usbc-power) + [system/gbgo-usbc-power.service](system/gbgo-usbc-power.service) (POSIX sh, polls every 2 s) handle chargers and devices plugged in later. **No kernel, driver or DT change is needed for that**: it talks to the chips from userspace over I2C (`i2c-tools`) and drives two PMIC GPIOs (`gpiod` 2.x).

| | Left USB-C | Right USB-C (the one marked for video) |
|---|---|---|
| USB PD charger plugged in after boot | charges (15 V, ~2 A) within ~3 s | same |
| USB 2 device plugged in after boot | works (internal hub port 1) | works (hub port 2) |
| USB 3 device plugged in after boot | enumerates at USB 2 speed: this port has no USB 3 lines | works at 5 Gbps |
| Plain 5 V charger without USB PD | not working (see Open) | same |
| Video out (DP Alt Mode) | not done | not done |

USB-A is internal hub port 3, the camera port 4.

## Install

```sh
sudo apt install i2c-tools gpiod
sudo install -m 755 scripts/gbgo-usbc-power /usr/local/sbin/
sudo install -m 644 system/gbgo-usbc-power.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now gbgo-usbc-power
```

Check: `sudo gbgo-usbc-power once` (one verbose pass per port); `journalctl -u gbgo-usbc-power` logs every action (`charger attached, requesting PDO 4 (15000 mV, was PDO 1)`, `consumer switch off, turning it on`, `PM6150 GPIO7 (5 V out) -> 1`).

It needs `a84000.i2c`, `888000.i2c` and the PM6150 GPIO chip (`pmic@0:gpio`) enabled, as in the default DTB.

## The hardware

Per port, a Samsung **S2MM005** PD controller (0x33) and an SM5508 MUIC (0x14) on its own I2C bus; DSDT device `EMEC` (`SAM0604`), handled on Windows by Samsung's `EmuEC.sys`:

| | Left port (EmuEC port 0) | Right port (port 1) |
|---|---|---|
| I2C controller | `a84000.i2c` (DSDT I2C8) | `888000.i2c` (DSDT I2C3) |
| PD / MUIC interrupt (active low, TLMM) | 4 / 10 | 3 / 24 |
| 5 V out to devices | PM6150 GPIO5 | PM6150 GPIO7 |

Charger: TI BQ25710 at 0x09, gauge at 0x0b, both on `i2c@890000`. ACPI PMIC GPIO numbering: PM01 pin 128+n = PM6150 GPIO n+1.

## S2MM005 commands

16-bit register address, big-endian. From Samsung's s2mm005 driver in their phone kernels (LineageOS `android_kernel_samsung_universal9810`, `drivers/ccic/`) and a Ghidra decompile of `EmuEC.sys` (`set_CP_Switch` at 0x140010268, `Set_Source_out5V` at 0x14001e640, GPIO function table at 0x1400443d0).

| What | How |
|---|---|
| PD state | read `0x0020`: byte 0 = policy-engine state (21 sink ready, < 15 source states, 17 waiting for source caps, 29 error recovery); byte 3 bit 0 attached, bit 1 we are source |
| Source offers (PDOs) | read `0x0260` (u32 header, then u32 PDOs) |
| Our sink capabilities | read `0x0220` (5/9/12/15/20 V at 2 A on this laptop) |
| Current request | read `0x0244`, object position = bits 30:28 |
| Select PDO n | write `0x0010` = `03 03 n`, then `03 02 11` (renegotiate) |
| CP switch status | write `0x0010` = `03 92`, then read 4 bytes at `0x0014` (byte 0 provider, byte 1 consumer) |
| Consumer (charge) switch on | write `0x0010` = `03 91 00 01 00 02` |
| Clear interrupt | write `0x0010` = `01`; MUIC: read `0x03`/`0x04` |

## What the service does (each port, every 2 s)

- **Charger attached** (state 21): select the best fixed PDO **up to 15 V** if the current request differs. Windows' EmuEC takes the most power among PDOs below 15.001 V; the boot firmware picks 12 V; it never goes to 20 V although the sink caps list it. Then close the consumer switch if it is open (it reopens after every renegotiation), acknowledge the interrupts and run `gbgo-charge once`, so charging starts immediately instead of at its next 60 s pass. `gbgo-charge` keeps relaying the gauge's requests as before; no other coordination is needed.
- **Device attached** (attached + we are source): hold that port's 5 V GPIO high. One `gpioset` per port holds the line; a released line reverts.
- **Charger without USB PD** (attached as sink, state never 21): close the consumer switch anyway; the BQ25710 accepts 5 V (AC_STAT set at 4.67 V). The S2MM005 drops these chargers after a few seconds though (see Open).
- **Otherwise**: 5 V GPIO held low, never on while a charger is on that port.

## Charge LED

ACPI `LED1` (`SAMM0611`, Windows `qchwnled7180`) is an RGB LED on the PM6150L LPG TRI-LED: channel 1 red/orange, 2 green, 3 blue (found by lighting each one). `GBGO_LED=1 gbgo-dtb-patch …` adds `led@1..3` (labels `gbgo:red/green/blue`) to the LPG node; `gbgo-usbc-power` then drives them (it loads `ledtrig-timer`):

| State | LED |
|---|---|
| Charging at the full contract (>= 15 V) | blue |
| Charging at a lower voltage (weaker PD charger) | red |
| Charger connected, battery Full | green |
| On battery, <= 10 % (`LOW_PCT` in the script) | red blinking |
| On battery, above | off |

Windows used red/orange (charging) and green (full) plus low-battery/error states; blue was unused. For a DT-only setup without the service, `linux,default-trigger = "sbs-4-000b-charging"` / `"sbs-4-000b-full"` on the red and green nodes work too.

## Lessons

- After a replug, both steps are needed: the higher-voltage contract **and** the consumer switch. The BQ25710's VBUS ADC read 0 V until the switch command.
- The BQ25710 ADC is off in battery-only low-power mode (ChargeOption0 bit 15); clear that bit for a VBUS measurement, or the reading is stale.
- Test the PDO choice offline with captured register bytes first: a first version misread the sink caps and requested 20 V for a minute.
- `gpioset -t 0` releases the line at once and it reverts; keep a `gpioset` running.
- After a full charge the gauge keeps its FULLY_CHARGED flag (BatteryStatus bit 5) for a while: seen still set at 98 %, so "Full" and no charging right after a replug is the gauge's hysteresis, not a fault (where it clears was not measured).

## Open

- **Chargers without USB PD:** the S2MM005 attaches as sink (state 17), gets no source capabilities, goes to error recovery and disconnects, then re-detects. Windows has a separate path through the SM5508 MUIC (DCP detection, Samsung AFC 9/12 V over D+/D-, EmuEC `sm5508_*`, `AFC_TXD` 0x46/0x79), not replicated.
- **DP Alt Mode** (right port): needs `mdss_dp`, Alt Mode VDMs through the S2MM005, and the Parade PS8743B mux (EmuEC `PS8743B_*`, `[DPMUX] USB3_ONLY / DP2_LANE_USB3 / DP4_LANE`; no Linux driver).
- Interrupts are polled; the PD/MUIC IRQ lines could drive the service instead.
- EmuEC has a second board-variant GPIO table (and its INF a separate 5G subsystem ID, `C1A1144D`): the 5 V GPIOs may differ on the LTE/5G model.
