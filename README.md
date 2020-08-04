# Overview

Xebow is a [nerves-based](https://nerves-project.org/) firmware for the
[Keybow](https://shop.pimoroni.com/products/keybow?variant=21246333190227)
keypad.

This project is in **early development**. Features and the API may be subject
to change.

- Join the `#nerves-keyboard` channel on the [elixir-lang Slack](https://elixir-slackin.herokuapp.com/)
to chat with us and keep up on the latest developments.
- Visit the [wiki](https://github.com/ElixirSeattle/xebow/wiki) to see past
meeting notes and other content.
- Planning meetings are open to all. Feel free to join if you would like to
familiarize yourself with the internals of Xebow or would like to find a place
to help out. The schedule is pinned in the Slack channel.

# Initial Setup

## Checking out the Project

    $ git clone git@github.com:ElixirSeattle/xebow.git
    $ cd xebow

## SSH Access (optional)

If you would like to flash firmware to the MicroSD card without having to remove
it from the keybow each time, you will need to set up SSH access. This also
provides access to a running iex shell for running commands directly on the
device.

If your SSH public key is not in your home directory's .ssh/ directory with one
of the following names, then you can specify the path to your public key by
setting the `NERVES_SSH_PUB_KEY` environment variable:

- id_rsa.pub
- id_ecdsa.pub
- id_ed25519.pub

## Building the Firmware

If you have not used nerves to build firmware before, you may need to install
several dependencies. See the [installation
guide](https://hexdocs.pm/nerves/installation.html) if this is your first time
using nerves.

The keybow uses a Raspberry Pi Zero WH, so the target would be `rpi0`. However,
to better support all the keybow features that xebow uses, a custom target has
been setup called `keybow` that you will need to use instead. To build and burn
the firmware:

    $ export MIX_TARGET=keybow
    $ mix deps.get
    $ mix firmware

## Writing the Firmware to the MicroSD Card

Insert the MicroSD card into an card reader attached to your computer and then
run:

    $ mix firmware.burn

The `mix firmware.burn` command will try to detect your MicroSD card and offer
to write the data to the card. **IMPORTANT: Triple-check that the device it
plans to write to is the MicroSD Card, or you could permanently delete data on
another device.**

## Booting the Keybow

Remove the MicroSD card and insert it into the keybow. Plug the keybow into the
computer and wait for it to boot. Once booted, the keypad should begin cycling
all keys through a rainbow of colors.

## Updating the firmware

The firmware can be updated while the Keybow is attached to your computer as
long as the Xebow firmware is running on it.

Build the firmware and upload it via SSH by running:

    $ mix firmware.upload

If you would like to perform these steps individually, use `mix firmware`
and `mix upload`.

Notes
- The upload needs to be run on a computer with the same SSH public key that was
  used when burning the SD card or else it won't be able to connect to the Keybow.
- If the `xebow.local` hostname can't be resolved, try unplugging the Keybow
  from the USB port, wait for the computer's USB disconnect notification, then
  plug the Keybow back in and try again after it's booted back up.

## Web Interface

The following instructions are for running the Xebow web interface on your
computer for a faster development cycle.

If this is your first time running the web interface, set up the web app with:

    $ mix setup

Start the web interface, which will be available at `http://localhost:4000`:

    $ mix phx.server

# Keyboard Layout

The xebow firmware sets up the keybow as a 10-key numpad. Turn the keypad so the
flashing LEDs are on the left of each key and the USB cord is facing right. In
this position, the keypad has the following layout:

```
+-----+-----+-----+
|  7  |  8  |  9  |
+-----+-----+-----+
|  4  |  5  |  6  |
+-----+-----+-----+
|  1  |  2  |  3  |
+-----+-----+-----+
|  0  | L-1 | L-2 |
+-----+-----+-----+
```

The `L-1` and `L-2` keys activate different "layers" of the keypad, which allows
mapping additional commands to each key. For example, holding `L-2` and hitting
`7` will trigger a command to flash the keypad red.

## Keyboard Shortcuts

- `L-1` + `9`: volume up
- `L-1` + `6`: volume down
- `L-1` + `8`: mute
- `L-2` + `7`: flash keypad red
- `L-2` + `9`: flash keypad green
- `L-2` + `4`: previous animation
- `L-2` + `6`: next animation
