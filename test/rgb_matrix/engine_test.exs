defmodule RGBMatrix.EngineTest do
  use ExUnit.Case

  alias RGBMatrix.{Animation, Engine}

  setup_all [
    :create_leds,
    :create_frame,
    :create_animation
  ]

  setup :create_paint_fn

  test "can set an animation", %{
    animation: animation
  } do
    assert Engine.set_animation(animation) == :ok
  end

  setup :set_animation

  test "can register a paintable function", %{
    paint_fn: paint_fn
  } do
    assert {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)
  end

  test "renders frames", %{
    frame: frame,
    paint_fn: paint_fn
  } do
    {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)
    assert_receive {:frame, ^frame}
  end

  describe "interaction events" do
    setup :create_interact_animation

    test "call the interact/3 Animation callback", %{
      interact_animation: interact_animation,
      leds: leds,
      paint_fn: paint_fn
    } do
      :ok = Engine.set_animation(interact_animation)
      {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

      interaction = hd(leds)
      assert Engine.interact(interaction) == :ok
      assert_receive {:interact, ^interaction}
    end
  end

  test "unregistering paintables is idempotent", %{
    frame: frame,
    paint_fn: paint_fn
  } do
    {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

    assert Engine.unregister_paintable(paint_fn) == :ok
    assert Engine.unregister_paintable(paint_fn) == :ok
    assert maybe_receive_some_frames(frame, 6)
    refute_receive {:frame, ^frame}
  end

  # Creates a module which renders the test frame
  # Renders are scheduled 10 ms apart.
  # Interactions render in 10 ms.
  defp create_animation(%{frame: frame, leds: leds}) do
    module_name = MockAnimation
    render_in = 17

    defmodule module_name do
      use Animation

      @frame frame
      @render_in render_in

      @impl true
      def new(_leds, _config), do: nil

      @impl true
      def render(_state, _config), do: {@render_in, @frame, nil}
    end

    [animation: Animation.new(module_name, leds)]
  end

  defp create_frame(%{leds: leds}) do
    color = Chameleon.RGB.new(100, 200, 0)

    frame =
      leds
      |> Enum.map(&{&1.id, color})
      |> Map.new()

    [frame: frame]
  end

  # This InteractAnimation module is used to test Engine.interact/1
  # The interact/3 callback sends the received data back to the test process
  defp create_interact_animation(%{leds: leds, line: line}) do
    module_name = :"InteractAnimation#{line}"
    test_runner_pid = self()

    defmodule module_name do
      use Animation

      @test_pid {:pid, test_runner_pid}

      @impl true
      def new(_leds, _config), do: nil

      @impl true
      def render(_leds, _config), do: {:never, %{}, nil}

      @impl true
      def interact(_state, _config, led) do
        {:pid, send_to} = @test_pid
        send(send_to, {:interact, led})
        {:ignore, nil}
      end
    end

    [interact_animation: Animation.new(module_name, leds)]
  end

  defp create_leds(_context),
    do: [leds: [Layout.LED.new(:l1, 0, 0)]]

  # A paint_fn is necessary for regstration with the engine.
  # This must be run as part of the setup for each test to make sure the pid
  # is that of the test process.
  defp create_paint_fn(_context) do
    pid = self()

    paint_fn = fn frame ->
      send(pid, {:frame, frame})
      :ok
    end

    [paint_fn: paint_fn]
  end

  # During unregistration, there is a chance the Engine could already be
  # performing a render, or may have multiple :render messages in its mailbox,
  # so it may send one or more frames to the given paintable anyway. We need to
  # receive and discard all frames.
  defp maybe_receive_some_frames(_frame, -1), do: false

  defp maybe_receive_some_frames(frame, frame_allowance) do
    receive do
      {:frame, ^frame} ->
        maybe_receive_some_frames(frame, frame_allowance)
    after
      100 ->
        true
    end
  end

  defp set_animation(%{animation: animation}),
    do: :ok = Engine.set_animation(animation)
end
