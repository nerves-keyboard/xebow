defmodule RGBMatrix.Effect do
  alias Layout.LED

  @callback new(leds :: list(LED.t()), config :: any) :: {render_in, any}
  @callback render(state :: any, config :: any) ::
              {list(RGBMatrix.any_color_model()), render_in, any}
  @callback key_pressed(state :: any, config :: any, led :: LED.t()) :: {render_in, any}

  @type t :: %__MODULE__{
          type: type,
          config: any,
          state: any
        }
  defstruct [:type, :config, :state]

  defmacro __using__(_) do
    quote do
      @behaviour RGBMatrix.Effect
    end
  end

  @type render_in :: non_neg_integer() | :never | :ignore

  @type type ::
          __MODULE__.CycleAll
          | __MODULE__.HueWave
          | __MODULE__.Pinwheel
          | __MODULE__.RandomSolid
          | __MODULE__.RandomKeypresses
          | __MODULE__.SolidColor
          | __MODULE__.Breathing
          | __MODULE__.SolidReactive
          | __MODULE__.Splash

  @doc """
  Returns a list of the available types of animations.
  """
  @spec types :: list(type)
  def types do
    [
      __MODULE__.CycleAll,
      __MODULE__.HueWave,
      __MODULE__.Pinwheel,
      __MODULE__.RandomSolid,
      __MODULE__.RandomKeypresses,
      __MODULE__.SolidColor,
      __MODULE__.Breathing,
      __MODULE__.SolidReactive,
      __MODULE__.Splash
    ]
  end

  @doc """
  Returns an effect's initial state.
  """
  @spec new(effect_type :: type, leds :: list(LED.t())) :: {render_in, t}
  def new(effect_type, leds) do
    config_module = Module.concat([effect_type, Config])
    effect_config = config_module.new()
    {render_in, effect_state} = effect_type.new(leds, effect_config)

    effect = %__MODULE__{
      type: effect_type,
      config: effect_config,
      state: effect_state
    }

    {render_in, effect}
  end

  @doc """
  Returns the next state of an effect based on its current state.
  """
  @spec render(effect :: t) :: {list(RGBMatrix.any_color_model()), render_in, t}
  def render(effect) do
    {colors, render_in, effect_state} = effect.type.render(effect.state, effect.config)
    {colors, render_in, %{effect | state: effect_state}}
  end

  @doc """
  Sends a key pressed event to an effect.
  """
  @spec key_pressed(effect :: t, led :: LED.t()) :: {render_in, t}
  def key_pressed(effect, led) do
    {render_in, effect_state} = effect.type.key_pressed(effect.state, effect.config, led)
    {render_in, %{effect | state: effect_state}}
  end
end
