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

    end

    test "should not write to stderr" do
      message = "octopus party"
      meta_capture = fn ->
        # asserting here means we can make sure it IS working, not just failing totally
        assert capture_io(fn ->
          output_message = Tester.log(message)
          send(self(), {:return, output_message})
        end)
      end
      assert capture_io(:stderr, meta_capture) === ""
      assert_receive {:return, message}
    end
  end

  describe "idempotency" do
    test "should return message unchanged" do
      message = "hello world"
      assert_log_result(message, &test_log/0)
    end

    test "labeled log should return message unchanged" do
      message = "beep boop"
      log_with_label = fn -> Tester.log(message, label: "some label") end
      assert_log_result(message, log_with_label)
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
