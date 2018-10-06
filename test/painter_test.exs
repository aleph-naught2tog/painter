defmodule Tester do
  use Painter, color: :red, name: "Tester"
  def test_log do
    Tester.log("hello world")
  end
end

defmodule PainterTest do
  use ExUnit.Case
  doctest Painter, import: true

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
      send_return_message = fn ->
        send(self(), {:return, Tester.log(message)})
      end
      meta_capture = fn ->
        # asserting here is just an extra level of safe
        assert capture_io(send_return_message)
      end
      assert capture_io(:stderr, meta_capture) === ""
      assert_receive({:return, message})
    end

    test "safe_raise should raise" do
      assert_raise(RuntimeError, fn -> Tester.safe_raise("apples") end)
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
    test "should handle binaries gracefully" do
      refute_raise(fn -> silent_log(fn -> Tester.log("pears") end) end)
    end

    test "should handle non-binaries gracefully" do
      refute_raise(fn -> silent_log(fn -> Tester.log(%{orange: "oranges", apple: :ok}) end) end)
    end

    test "should handle nil gracefully" do
      refute_raise(fn -> silent_log(fn -> Tester.log(nil) end) end)
    end
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
