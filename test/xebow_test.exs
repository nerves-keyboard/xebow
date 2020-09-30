defmodule XebowTest do
  use ExUnit.Case

  alias RGBMatrix.Animation

  setup_all [
    :create_mock_animation_list,
    :create_single_animation_list,
    :create_single_schema
  ]

  test "has layout" do
    assert %Layout{} = Xebow.layout()
  end

  describe "can get and set active animation types" do
    test "with a list of animation modules", %{
      mock_animation_list: mock_animation_list
    } do
      assert Xebow.set_active_animation_types(mock_animation_list) == :ok
      assert Xebow.get_active_animation_types() == mock_animation_list
    end

    test "with an empty list" do
      assert Xebow.set_active_animation_types([]) == :ok
      assert Xebow.get_active_animation_types() == []
    end
  end

  describe "animations can be cycled" do
    setup %{mock_animation_list: mock_animation_list} do
      Xebow.set_active_animation_types(mock_animation_list)
    end

    test "forward" do
      assert Xebow.next_animation() == :ok
    end

    test "backward" do
      assert Xebow.previous_animation() == :ok
    end

    test "through the list, which wraps in both directions", %{
      mock_animation_list: mock_animation_list
    } do
      double_count = length(mock_animation_list) * 2

      for _ <- 1..double_count do
        assert Xebow.next_animation() == :ok
      end

      for _ <- 1..double_count do
        assert Xebow.previous_animation() == :ok
      end
    end
  end

  setup %{single_animation_list: single_animation_list} do
    Xebow.set_active_animation_types(single_animation_list)
  end

  describe "can get the config and schema" do
    test "of the current active animation", %{
      single_animation_list: [animation_module],
      single_schema: single_schema
    } do
      config_module = Module.concat(animation_module, "Config")

      assert {%^config_module{}, ^single_schema} = Xebow.get_animation_config()
    end

    test "or nil when no animations active" do
      Xebow.set_active_animation_types([])

      assert Xebow.get_animation_config() == nil
    end
  end

  test "config of the current animation can be updated", %{} do
    single_config = Xebow.get_animation_config()
    update_params = %{test_field: :b}

    assert Xebow.update_animation_config(update_params) == :ok
    refute Xebow.get_animation_config() == single_config

    {config, _schema} = Xebow.get_animation_config()

    assert config.test_field == :b
  end

  describe "configurables" do
    setup :create_config_fn

    test "can be registered, which is idempotent", %{
      config_fn: config_fn
    } do
      assert Xebow.register_configurable(config_fn) == {:ok, config_fn}
      assert Xebow.register_configurable(config_fn) == {:ok, config_fn}

      Xebow.next_animation()
      config = Xebow.get_animation_config()

      assert_receive {:config, ^config}
      refute_receive {:config, ^config}
    end

    test "can be unregistered, which is idempotent", %{
      config_fn: config_fn
    } do
      Xebow.register_configurable(config_fn)

      assert Xebow.unregister_configurable(config_fn) == :ok
      assert Xebow.unregister_configurable(config_fn) == :ok

      Xebow.previous_animation()
      config = Xebow.get_animation_config()

      refute_receive {:config, ^config}
    end

    test "are called when switching animations", %{
      config_fn: config_fn
    } do
      Xebow.register_configurable(config_fn)

      Xebow.next_animation()
      config = Xebow.get_animation_config()
      assert_receive {:config, ^config}
    end

    test "can return :unregister to unregister themselves" do
      pid = self()
      unregister_message = {:config, "unregister"}

      unregister_config_fn = fn _config ->
        send(pid, unregister_message)
        :unregister
      end

      assert Xebow.register_configurable(unregister_config_fn) == {:ok, unregister_config_fn}

      Xebow.next_animation()
      assert_receive ^unregister_message

      Xebow.next_animation()
      refute_receive ^unregister_message
    end
  end

  # This must be added in `setup` so the pid belongs to the test process.
  defp create_config_fn(_context) do
    pid = self()

    config_fn = fn config ->
      send(pid, {:config, config})
      :ok
    end

    [config_fn: config_fn]
  end

  defp create_mock_animation_list(_context) do
    mock_animation_list = [
      Type1,
      Type2,
      Type3
    ]

    Enum.each(mock_animation_list, fn module_name ->
      Module.create(module_name, mock_animation_module(module_name), __ENV__)
    end)

    [mock_animation_list: mock_animation_list]
  end

  defp create_single_animation_list(_context), do: [single_animation_list: [Type1]]

  defp create_single_schema(_context) do
    schema = [
      test_field: %RGBMatrix.Animation.Config.FieldType.Option{
        options: [:a, :b],
        default: :a,
        doc: []
      }
    ]

    [single_schema: schema]
  end

  defp mock_animation_module(Type1) do
    quote do
      use Animation

      field :test_field, :option,
        options: ~w(a b)a,
        default: :a

      @impl true
      def new(_leds, _config), do: nil

      @impl true
      def render(_state, _config), do: {1000, %{}, nil}
    end
  end

  defp mock_animation_module(_) do
    quote do
      use Animation

      @impl true
      def new(_leds, _config), do: nil

      @impl true
      def render(_state, _config), do: {1000, %{}, nil}
    end
  end
end
