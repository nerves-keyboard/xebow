defmodule XebowWeb.AnimationsLive do
  @moduledoc false

  alias RGBMatrix.Animation
  alias Xebow.Settings

  use XebowWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    active_animation_types =
      case Settings.load_active_animations() do
        {:ok, active_animation_types} ->
          active_animation_types

        {:error, reason} ->
          Logger.warn("Failed to load active animations: #{inspect(reason)}")
          Animation.types()
      end

    animations =
      animations()
      |> Enum.map(fn animation ->
        if animation.module in active_animation_types do
          %{animation | is_active: true}
        else
          animation
        end
      end)

    {:ok, assign(socket, animations: animations)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_animation", params, socket) do
    animations =
      socket.assigns.animations
      |> Enum.map(fn animation ->
        if animation.id == params["id"] do
          is_active = params["value"] == "true"
          %{animation | is_active: is_active}
        else
          animation
        end
      end)

    animations
    |> Enum.filter(& &1.is_active)
    |> Enum.map(& &1.module)
    |> Settings.save_active_animations!()

    {:noreply, assign(socket, animations: animations)}
  end

  defp animations do
    Animation.types()
    |> Enum.map(fn animation_module ->
      name = Animation.type_name(animation_module)

      id =
        name
        |> String.replace(" ", "_")
        |> String.downcase()

      %{
        module: animation_module,
        id: id,
        name: name,
        is_active: false
      }
    end)
    |> Enum.sort(&(&1.name < &2.name))
  end
end
