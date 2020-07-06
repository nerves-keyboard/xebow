defmodule XebowWeb.EffectConfigComponent do
  use XebowWeb, :live_component

  @mapping %{
    RGBMatrix.Effect.Config.Option => XebowWeb.EffectConfigOptionComponent,
    RGBMatrix.Effect.Config.Integer => XebowWeb.EffectConfigIntegerComponent
  }

  def component_for(module) do
    Map.fetch!(@mapping, module)
  end
end
