defmodule ConfigTest do
  use ExUnit.Case

  describe "Animation configurations" do
    test "can be created" do
      assert %RGBMatrix.Animation.HueWave.Config{direction: :right, speed: 4, width: 20} ==
               RGBMatrix.Animation.Config.new_config(
                 RGBMatrix.Animation.HueWave.Config,
                 RGBMatrix.Animation.HueWave.Config.schema(),
                 %{}
               )
    end

    test "can be updated" do
      hue_wave_config =
        RGBMatrix.Animation.Config.new_config(
          RGBMatrix.Animation.HueWave.Config,
          RGBMatrix.Animation.HueWave.Config.schema(),
          %{}
        )

      assert %RGBMatrix.Animation.HueWave.Config{direction: :left, speed: 4, width: 20} ==
               RGBMatrix.Animation.Config.update_config(
                 hue_wave_config,
                 RGBMatrix.Animation.HueWave.Config.schema(),
                 %{"direction" => "left"}
               )
    end
  end
end
