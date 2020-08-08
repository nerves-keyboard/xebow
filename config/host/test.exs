import Config

config :xebow, settings_path: "priv/settings_test"

config :xebow, XebowWeb.Endpoint,
  http: [port: 4002],
  server: false,
  code_reloader: false

config :logger, level: :error
