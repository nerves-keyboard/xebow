# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :xebow, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1581654358"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Phoenix config:
# Common config between host and targets
# FIXME: uncomment the following 6 lines to configure Phoenix
# config :xebow, XebowWeb.Endpoint,
#   server: true,
#   secret_key_base: "M6xyyGOeCywsLjrSclRl8aNucNyqPe6JV2g3nZIs2+S+NZ2TujWfIL8T69qwYC+G",
#   render_errors: [view: XebowWeb.ErrorView, accepts: ~w(html json), layout: false],
#   pubsub_server: Xebow.PubSub,
#   live_view: [signing_salt: "JbJukpOp"],

# Use Jason for JSON parsing in Phoenix
# FIXME: uncomment the following line to configure Phoenix
# config :phoenix, :json_library, Jason

if Mix.target() != :host do
  import_config "target.exs"
else
  import_config "host.exs"
end
