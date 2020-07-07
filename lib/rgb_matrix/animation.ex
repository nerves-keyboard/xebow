defmodule RGBMatrix.Animation do
  alias Layout.LED

  @callback new(leds :: list(LED.t()), config :: any) :: {render_in, any}
  @callback render(state :: any, config :: any) ::
              {list(RGBMatrix.any_color_model()), render_in, any}
  @callback interact(state :: any, config :: any, led :: LED.t()) :: {render_in, any}

  @type t :: %__MODULE__{
          type: type,
          config: any,
          state: any
        }
  defstruct [:type, :config, :state]

  defmacro __using__(_) do
    quote do
      @behaviour RGBMatrix.Animation
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
      __MODULE__.SolidReactive
    ]
  end

  @doc """
  Returns an animation's initial state.
  """
  @spec new(animation_type :: type, leds :: list(LED.t())) :: {render_in, t}
  def new(animation_type, leds) do
    config_module = Module.concat([animation_type, Config])
    animation_config = config_module.new()
    {render_in, animation_state} = animation_type.new(leds, animation_config)

    animation = %__MODULE__{
      type: animation_type,
      config: animation_config,
      state: animation_state
    }

    {render_in, animation}
  end

  @doc """
  Returns the next state of an animation based on its current state.
  """
  @spec render(animation :: t) :: {list(RGBMatrix.any_color_model()), render_in, t}
  def render(animation) do
    {colors, render_in, animation_state} =
      animation.type.render(animation.state, animation.config)

    {colors, render_in, %{animation | state: animation_state}}
  end

  @doc """
  Sends an interaction event to an animation.
  """
  @spec interact(animation :: t, led :: LED.t()) :: {render_in, t}
  def interact(animation, led) do
    {render_in, animation_state} = animation.type.interact(animation.state, animation.config, led)
    {render_in, %{animation | state: animation_state}}
  end

  @doc """
  Gets the current configuration and the configuration schema from an animation.
  """
  @spec get_config(animation :: t) :: {struct, keyword(struct)}
  def get_config(animation) do
    %config_module{} = config = animation.config
    config_schema = config_module.schema()

    {config, config_schema}
  end

  @doc """
  Updates the configuration of an animation.
  """
  @spec update_config(animation :: t, params :: map) :: t
  def update_config(animation, params) do
    %config_module{} = config = animation.config

    config = config_module.update(config, params)

    %{animation | config: config}
  end
end
