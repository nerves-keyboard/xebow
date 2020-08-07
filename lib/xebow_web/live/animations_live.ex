defmodule XebowWeb.AnimationsLive do
  @moduledoc false

  alias RGBMatrix.Animation

  use XebowWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    animations =
      Animation.types()
      |> Enum.map(fn animation_module ->
        module_name =
          animation_module
          |> to_string()
          |> String.split(".")
          |> List.last()

        id =
          module_name
          |> String.replace(~r/([A-Z])/, "_\\1")
          |> String.downcase()
          |> String.trim_leading("_")

        name =
          module_name
          |> String.replace(~r/([A-Z])/, " \\1")
          |> String.trim_leading()

        %{
          module: animation_module,
          id: id,
          name: name,
          active: false
        }
      end)
      |> Enum.sort(&(&1.name < &2.name))

    socket = assign(socket, animations: animations)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_animation", _params, socket) do
    {:noreply, socket}
  end
end
