defmodule PainterTest do
  use ExUnit.Case
  doctest Painter

  describe "idempotency" do
    test "should return message unchanged"
  end

  @tag :skip
  describe "handling types" do
    test "should handle binaries gracefully"
    test "should handle non-binaries gracefully"
    test "should not add extra strings"
  end

  @tag :skip
  describe "compatibility" do
    test "should not use colors if ANSI not enabled"
  end

  test "tests work" do
    assert true
  end
end
