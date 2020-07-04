defmodule Xebow.EngineTest do
  use ExUnit.Case

  alias Xebow.{Animation, Engine, Frame}

  # Creates a Xebow.Paintable module that emits frames to the test suite process.
  defp paintable(%{test: test_name}) do
    process = self()
    module_name = String.to_atom("#{test_name}-paintable")

    Module.create(
      module_name,
      quote do
        def get_paint_fn do
          fn frame ->
            send(unquote(process), {:frame, frame})
          end
        end
      end,
      Macro.Env.location(__ENV__)
    )

    %{paintable: module_name}
  end

  # Creates a single pixel, single frame animation.
  defp solid_animation(red \\ 255, green \\ 127, blue \\ 0) do
    pixels = [{0, 0}]
    color = Chameleon.RGB.new(red, green, blue)
    frame = Frame.solid_color(pixels, color)

    animation =
      Animation.new(
        type: Animation.Static,
        frames: [frame],
        delay_ms: 10,
        loop: 1
      )

    {animation, frame}
  end

  setup [:paintable]

  test "renders a solid animation", %{paintable: paintable} do
    {animation, frame} = solid_animation()

    start_supervised!({Engine, {animation, [paintable]}})

    assert_receive {:frame, ^frame}
  end

  test "renders a multi-frame, multi-pixel animation", %{paintable: paintable} do
    pixels = [
      {0, 0},
      {0, 1},
      {1, 0},
      {1, 1}
    ]

    frames = [
      Frame.solid_color(pixels, Chameleon.Keyword.new("red")),
      Frame.solid_color(pixels, Chameleon.Keyword.new("green")),
      Frame.solid_color(pixels, Chameleon.Keyword.new("blue")),
      Frame.solid_color(pixels, Chameleon.Keyword.new("white"))
    ]

    animation =
      Animation.new(
        type: Animation.Static,
        frames: frames,
        delay_ms: 10,
        loop: 1
      )

    start_supervised!({Engine, {animation, [paintable]}})

    Enum.each(frames, fn frame ->
      assert_receive {:frame, ^frame}
    end)
  end

  test "can play a different animation", %{paintable: paintable} do
    {animation, _frame} = solid_animation()
    {animation_2, frame_2} = solid_animation(127, 127, 127)

    start_supervised!({Engine, {animation, [paintable]}})

    :ok = Engine.play_animation(animation_2)

    assert_receive {:frame, ^frame_2}
  end

  test "can register and unregister paintables", %{paintable: paintable} do
    {animation, frame} = solid_animation()
    {animation_2, frame_2} = solid_animation(127, 127, 127)

    start_supervised!({Engine, {animation, []}})

    :ok = Engine.register_paintable(paintable)

    assert_receive {:frame, ^frame}

    :ok = Engine.unregister_paintable(paintable)
    :ok = Engine.play_animation(animation_2)

    refute_receive {:frame, ^frame_2}
  end
end
