defmodule Xebow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @leds Xebow.layout() |> Layout.leds()

  if Mix.target() == :host do
    defp maybe_validate_firmware,
      do: nil
  else
    defp maybe_validate_firmware,
      do: Nerves.Runtime.validate_firmware()
  end

  def start(_type, _args) do
    maybe_validate_firmware()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xebow.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Xebow.Worker.start_link(arg)
        # {Xebow.Worker, arg},
        # Engine must be started before Xebow
        {RGBMatrix.Engine, @leds},
        Xebow,
        # Phoenix:
        XebowWeb.Telemetry,
        {Phoenix.PubSub, name: Xebow.PubSub},
        XebowWeb.Endpoint
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Xebow.Worker.start_link(arg)
      # {Xebow.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Xebow.Worker.start_link(arg)
      # {Xebow.Worker, arg},
      Xebow.HIDGadget,
      Xebow.LEDs,
      Xebow.Keyboard
    ]
  end

  def target() do
    Application.get_env(:xebow, :target)
  end
end
