defmodule XebowWeb.AnimationsLiveTest do
  use XebowWeb.ConnCase

  import Phoenix.LiveViewTest

  test "shows available animations", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.animations_path(conn, :index))

    assert view
           |> element("#animation_breathing")
           |> has_element?()
  end
end
