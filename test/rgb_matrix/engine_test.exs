defmodule RGBMatrix.EngineTest do
  use ExUnit.Case

  alias RGBMatrix.{Animation, Engine}

  setup_all [
    :create_leds,
    :create_frame,
    :create_animation
  ]

  setup :create_paint_fn

  describe "set_animation/1" do
    @tag capture_log: true
    test "crashes the engine when called with a non-animation" do
      Process.monitor(Engine)

      assert Engine.set_animation("We are") == :ok

      assert_receive_down()
    end

    test "can set an animation", %{
      animation: animation
    } do
      Process.monitor(Engine)

      assert Engine.set_animation(animation) == :ok

      refute_receive_down()
    end
  end

  setup :set_animation

  describe "register_paintable/1" do
    @tag capture_log: true
    test "crashes the engine when called with a non-function" do
      Process.monitor(Engine)
      fake_paint_fn = "the knights"

      assert {:ok, ^fake_paint_fn, _frame} = Engine.register_paintable(fake_paint_fn)

      assert_receive_down()
    end

    test "registers a paintable function", %{
      paint_fn: paint_fn
    } do
      Process.monitor(Engine)

      assert {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

      refute_receive_down()
    end
  end

  describe "renders frames" do
    test "by calling registered paintables with the frame", %{
      frame: frame,
      paint_fn: paint_fn
    } do
      {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

      assert_receive {:frame, ^frame}
    end
  end

  describe "interact/1" do
    setup :create_interact_animation

    test "calls the current animation's interact/3 callback", %{
      interact_animation: interact_animation,
      leds: leds,
      paint_fn: paint_fn
    } do
      Process.monitor(Engine)
      :ok = Engine.set_animation(interact_animation)
      {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

      interaction = "who say"
      assert Engine.interact(interaction) == :ok
      assert_receive {:interact, ^interaction}

      interaction = hd(leds)
      assert Engine.interact(interaction) == :ok
      assert_receive {:interact, ^interaction}

      refute_receive_down()
    end
  end

  describe "unregister_paintable/1" do
    test "ignores input which is not a registered paintable function", %{
      frame: frame,
      paint_fn: paint_fn
    } do
      Process.monitor(Engine)
      {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)
      fake_paint_fn = "NE!"

      assert Engine.unregister_paintable(fake_paint_fn) == :ok
      assert_receive {:frame, ^frame}

      refute_receive_down()
    end

    test "unregisters paintables", %{
      frame: frame,
      paint_fn: paint_fn
    } do
      Process.monitor(Engine)
      {:ok, ^paint_fn, _frame} = Engine.register_paintable(paint_fn)

      assert Engine.unregister_paintable(paint_fn) == :ok
      maybe_receive_some_frames(frame)
      refute_receive {:frame, ^frame}

      refute_receive_down()
    end
  end

  # Creates a module which renders the test frame
  # Renders are scheduled 10 ms apart.
  # Interactions render in 10 ms.
  defp create_animation(%{frame: frame, leds: leds}) do
    module_name = MockAnimation
    render_in = 5

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

      # This must be in a raw AST form to prevent compilation warnings
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
  # so it may send one or more frames to the given paintable anyway. So, we
  # to receive and discard all frames.
  defp maybe_receive_some_frames(frame) do
    receive do
      {:frame, ^frame} ->
        maybe_receive_some_frames(frame)
    after
      100 ->
        true
    end
  end

  defp set_animation(%{animation: animation}),
    do: :ok = Engine.set_animation(animation)

  defp assert_receive_down do
    assert_receive {:DOWN, _ref, :process, _object, _reason}
  end

  defp refute_receive_down do
    refute_receive {:DOWN, _ref, :process, _object, _reason}
  end
end
