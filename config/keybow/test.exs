import Config

config :xebow, XebowWeb.Endpoint,
  http: [port: 4002],
  server: false,
  code_reloader: false

config :logger, level: :warn
