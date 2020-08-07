defmodule XebowWeb.AnimationsLive do
  @moduledoc false

  alias RGBMatrix.Animation

  use XebowWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, animations: animations())}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_animation", _params, socket) do
    {:noreply, socket}
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
        active: false
      }
    end)
    |> Enum.sort(&(&1.name < &2.name))
  end
end
