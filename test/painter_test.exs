defmodule PainterTest do
  use ExUnit.Case
  doctest Painter

  test "greets the world" do
    assert Painter.hello() == :world
  end
end
