defmodule LogHelperTest do
  alias TestHelpers.LogHelper

  use ExUnit.Case
  doctest LogHelper

  import ExUnit.CaptureIO

  defmodule Tester do
    use Painter, color: :magenta, name: "Tester"
  end

  defp test_log do
    Tester.log("ducks are cool")
  end

  describe "assertions" do
    test "assert_log should match assert capture_io" do
      was_test_assert_true? = LogHelper.assert_log(&test_log/0)
      was_real_assert_true? = assert capture_io(&test_log/0)
      assert was_real_assert_true? === was_test_assert_true?
    end

    test "should assert true results" do
      LogHelper.assert_log_result("ducks are cool", &test_log/0)
    end

    test "should refute false results" do
      LogHelper.refute_log_result("orange", &test_log/0)
    end
  end
end