defmodule RGBMatrix.AnimationTest do
  use ExUnit.Case

  alias Layout.LED
  alias RGBMatrix.Animation

  setup_all [
    :create_leds,
    :create_frame,
    :create_animation_module,
    :create_config,
    :create_animation,
    :create_schema
  ]

  test "can get an animation type's human-readable name" do
    assert Animation.type_name(MockHueWave) == "Mock Hue Wave"
    assert Animation.type_name(MockAnimations.Mock.HueWave) == "Hue Wave"
    assert Animation.type_name(Mock.Animations.Hue.Wave) == "Wave"
  end

  test "can create a new animation", %{
    animation: animation,
    animation_module: animation_module,
    leds: leds
  } do
    assert ^animation = Animation.new(animation_module, leds)
  end

  test "rendering returns a delay, frame, and the maybe-updated animation", %{
    animation: animation,
    config: config,
    frame: frame
  } do
    assert {1000, ^frame, animation} = Animation.render(animation)
    assert animation.state == [:render, :new]
    assert animation.config == config
  end

  test "interaction returns a delay and the maybe-updated animation", %{
    animation: animation,
    config: config,
    leds: leds
  } do
    led = hd(leds)

    assert {0, animation} = Animation.interact(animation, led)
    assert animation.state == [{:interact, led}, :new]
    assert animation.config == config
  end

  test "can get the config and schema", %{
    animation: animation,
    config: config,
    schema: schema
  } do
    assert Animation.get_config(animation) == {config, schema}
  end

  test "can update the config of the provided animation", %{
    animation: animation,
    config: config
  } do
    params = %{"test_integer" => "5", test_option: :b}
    updated_config = %{config | test_option: :b, test_integer: 5}

    assert animation = %Animation{} = Animation.update_config(animation, params)
    refute animation.config == config
    assert animation.config == updated_config
  end

  defp create_leds(_context),
    do: [leds: [LED.new(:l1, 0, 0)]]

  defp create_frame(_context) do
    [frame: %{}]
  end

  defp create_animation_module(%{frame: frame, leds: leds}) do
    animation_module = MockHueWave
    config_module = config_module_name(animation_module)

    defmodule animation_module do
      use Animation

      @config_module config_module
      @frame frame
      @leds leds

      field :test_option, :option,
        default: :a,
        options: ~w(a b)a,
        doc: [
          name: "Testing Option",
          description: "valid option",
          other: :atom
        ]

      field :test_integer, :integer,
        default: 0,
        min: 0,
        max: 5,
        step: 5,
        doc: [
          name: "Testing Integer",
          description: "valid integer"
        ]

      @impl true
      def new(leds, config) do
        assert leds == @leds
        assert config.__struct__ == @config_module

        [:new]
      end

      @impl true
      def render(state, config) do
        assert config.__struct__ == @config_module

        state = [:render | state]

        {1000, @frame, state}
      end

      @impl true
      def interact(state, config, led) do
        assert config.__struct__ == @config_module
        assert Enum.member?(@leds, led)

        state = [{:interact, led} | state]

        {0, state}
      end
    end

    [animation_module: animation_module]
  end

  defp create_config(%{animation_module: animation_module}) do
    config_module = config_module_name(animation_module)

    config = struct(config_module, %{test_integer: 0, test_option: :a})

    [config: config]
  end

  defp create_animation(%{animation_module: animation_module, config: config}) do
    animation = %Animation{
      type: animation_module,
      config: config,
      state: [:new]
    }

    [animation: animation]
  end

  defp create_schema(_context) do
    schema = [
      test_integer: %RGBMatrix.Animation.Config.FieldType.Integer{
        default: 0,
        min: 0,
        max: 5,
        step: 5,
        doc: [
          name: "Testing Integer",
          description: "valid integer"
        ]
      },
      test_option: %RGBMatrix.Animation.Config.FieldType.Option{
        default: :a,
        options: [:a, :b],
        doc: [
          name: "Testing Option",
          description: "valid option",
          other: :atom
        ]
      }
    ]

    [schema: schema]
  end

  defp config_module_name(animation_module),
    do: Module.concat(animation_module, "Config")
end
