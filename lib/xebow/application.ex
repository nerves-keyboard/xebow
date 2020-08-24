defmodule Xebow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Xebow.Settings

  @leds Xebow.layout(Mix.target()) |> Layout.leds()

  if Mix.target() == :host do
    defp maybe_validate_firmware,
      do: nil
  else
    defp maybe_validate_firmware,
      do: Nerves.Runtime.validate_firmware()
  end

  def start(_type, _args) do
    Settings.create_dir!()
    maybe_create_animation_settings()

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

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        maybe_validate_firmware()
        {:ok, pid}

      error ->
        error
    end
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Xebow.Worker.start_link(arg)
      # {Xebow.Worker, arg},
    ]
  end

  def children(:keybow) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Xebow.Worker.start_link(arg)
      # {Xebow.Worker, arg},
      Xebow.HIDGadget,
      Xebow.Keybow.LEDs,
      Xebow.Keybow.Keyboard
    ]
  end

  def children(:excalibur) do
    [
      Xebow.HIDGadget,
      Xebow.Excalibur.Keyboard
    ]
  end

  def target() do
    Application.get_env(:xebow, :target)
  end

  defp maybe_create_animation_settings do
    unless Settings.active_animations_file_exists?() do
      RGBMatrix.Animation.types()
      |> Settings.save_active_animations!()
    end
  end
end
