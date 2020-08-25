import Config

config :nerves, rpi_v2_ack: true

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]

# Nerves Runtime can enumerate hardware devices and send notifications via
# SystemRegistry. This slows down startup and not many programs make use of
# this feature.

config :nerves_runtime, :kernel, use_system_registry: false

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

keys =
  [
    System.get_env("NERVES_SSH_PUB_KEY", ""),
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    IO.write(:stderr, """
    Warning: No SSH public key found. You will not be able to remotely
    connect to the device to access the iex shell or updating firmware.

    If you have an SSH public key, you can set NERVES_SSH_PUB_KEY to
    the path of the key. Otherwise, you can still flash the firmware
    manually.
    """)

config :nerves_firmware_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure the network using vintage_net
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"bond0", %{type: VintageNetDirect}}
  ]

config :mdns_lite,
  # The `host` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  mdns_lite also advertises
  # "nerves.local" for convenience. If more than one Nerves device is on the
  # network, delete "nerves" from the list.

  host: [:hostname, "xebow"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      name: "Xebow Web Interface",
      protocol: "http",
      transport: "tcp",
      port: 80
    }
  ]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Phoenix config:
# Configures the endpoint
config :xebow, XebowWeb.Endpoint,
  http: [port: 80, ip: {0, 0, 0, 0}],
  url: [host: "xebow.local", port: 80],
  code_reloader: false

config :xebow, settings_path: "/root/settings"

import_config "#{Mix.env()}.exs"
