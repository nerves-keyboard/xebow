defmodule XebowWeb.AnimationConfigComponent do
  @moduledoc false
  use XebowWeb, :live_component

  @mapping %{
    RGBMatrix.Animation.Config.FieldType.Option => XebowWeb.AnimationConfigOptionComponent,
    RGBMatrix.Animation.Config.FieldType.Integer => XebowWeb.AnimationConfigIntegerComponent
  }

  def component_for(module) do
    Map.fetch!(@mapping, module)
  end
end
