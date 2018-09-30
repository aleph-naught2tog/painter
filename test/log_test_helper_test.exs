defmodule LogTestHelperTest do
  alias Helpers.LogTestHelper

  use ExUnit.Case
  doctest LogTestHelper

  import ExUnit.CaptureIO

  defmodule Tester do
    use Painter, color: :magenta, name: "Tester"
  end

  defp test_log do
    Tester.log("ducks are cool")
  end

  describe "test assertions" do
    test "assert_log should match assert capture_io" do
      was_test_assert_true? = LogTestHelper.assert_log(&test_log/0)
      was_real_assert_true? = assert capture_io(&test_log/0)
      assert was_real_assert_true? === was_test_assert_true?
    end

    test "should match real results" do
      LogTestHelper.assert_log_result("ducks are cool", &test_log/0)
    end

    test "should fail false results" do
      LogTestHelper.refute_log_result("orange", &test_log/0)
    end
  end
end