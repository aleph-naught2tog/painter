defmodule LogHelperTest do
  import TestHelpers.LogHelper

  use ExUnit.Case
  doctest TestHelpers.LogHelper, import: true

  import ExUnit.CaptureIO

  defmodule Tester do
    use Painter, color: :magenta, name: "Tester"
  end

  defp test_log do
    Tester.log("ducks are cool")
  end

  describe "assertions" do
    test "silent_log should not output" do
      output = capture_io(&test_log/0)
      refute output === capture_io(fn -> silent_log(&test_log/0) end)
      assert "" === capture_io(fn -> silent_log(&test_log/0) end)
    end

    test "assert_log should match assert capture_io" do
      was_test_assert_true? = assert_log(&test_log/0)
      was_real_assert_true? = assert capture_io(&test_log/0)
      assert was_real_assert_true? === was_test_assert_true?
    end

    test "should assert true results" do
      assert_log_result("ducks are cool", &test_log/0)
    end

    test "should refute false results" do
      refute_log_result("orange", &test_log/0)
    end

    test "refute_raise should detect raises when present and fail" do
      assert_raise(ExUnit.AssertionError, fn -> refute_raise(fn -> raise("apples") end) end)
    end

    test "refute_raise should pass with no raises" do
      refute_raise(fn -> 1 / 1 end)
    end
  end
end