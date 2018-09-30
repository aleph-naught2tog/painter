defmodule Tester do
  use Painter, color: :red, name: "Tester"
  def test_log do
    Tester.log("hello world")
  end
end

defmodule PainterTest do
  use ExUnit.Case
  doctest Painter

  import ExUnit.CaptureIO
  import TestHelpers.ColorHelper
  import TestHelpers.LogHelper

  import Tester, only: [test_log: 0]

  describe "basic usage" do
    test "should have ansi" do
      assert has_any_ansi(&test_log/0)
    end

    test "should write to stdin" do
      assert capture_io(&test_log/0)
      assert capture_io(:stderr, &test_log/0) === ""
    end
  end

  describe "idempotency" do
    test "should return message unchanged" do
      message = "hello world"
      assert_log_result(message, &test_log/0)
    end

    test "labeled log should return message unchanged" do
      message = "beep boop"
      result_message = Tester.log(message, label: "here's the label")
      assert message === result_message
    end
  end

  describe "handling types" do
    @describetag :skip
    test "should handle binaries gracefully"
    test "should handle non-binaries gracefully"
    test "should not add extra strings"
  end

  describe "compatibility" do
    @describetag :skip
    test "should not use colors if ANSI not enabled"
  end

  test "assert only accepts true" do
    assert true
  end

  test "refute only accepts false" do
    refute false
  end
end
