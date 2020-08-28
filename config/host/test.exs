import Config

config :xebow,
  settings_path: "priv/settings_test",
  leds: [
    %{id: :l1, x: 0, y: 0},
    %{id: :l2, x: 2, y: 1.5},
    %{id: :l3, x: 3, y: 3}
  ],
  keys: [
    %{id: :k1, x: 0, y: 0, opts: [led: :l1]},
    %{id: :k2, x: 2, y: 1.5, opts: [width: 1.5, height: 2, led: :l2]},
    %{id: :k3, x: 5, y: 0}
  ]

config :xebow, XebowWeb.Endpoint,
  http: [port: 4002],
  server: false,
  code_reloader: false

config :logger, level: :warn
