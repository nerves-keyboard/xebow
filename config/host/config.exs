import Config

# Phoenix config:
# Configures the endpoint
config :xebow, XebowWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  code_reloader: true

import_config "#{Mix.env()}.exs"
