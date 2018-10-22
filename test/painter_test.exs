defmodule Tester do
  use Painter

  def test_log do
    Tester.log("hello world")
  end

  def test_debug do
    Tester.debug("apples")
  end
end

defmodule Skip do
  defmacro skip_without_ansi do
    unless IO.ANSI.enabled?() do
      IO.puts("\n       <<< WARNING >>>")
      IO.puts("ANSI is not enabled on this device.")
      IO.puts(" Tests that require it will skip.")
      IO.puts("       <<< -- -- -- >>>\n")
      :skip
    end
  end
end

defmodule PainterTest do
  use ExUnit.Case
  doctest Painter, import: true

  import ExUnit.CaptureIO
  import TestHelpers.ColorHelper
  import TestHelpers.LogHelper
  
  require Skip
  import Skip

  import Tester

  
  describe "highlighting" do
    test "has only marked" do
      message = "apples are tasty"
      <<"apples", _rest::binary>> = message
      rules = [red: "apples"]
      apples = mark_up("apples", :red)
      expected = apples <> " are tasty"
      result = capture_io(fn -> Tester.log(message, mark_list: rules) end)
      assert String.ends_with?(result, expected <> "\n")
    end
 
    test "should allow weird lists" do
      
      message = "apples are tasty"
      <<"apples", " ", "are", rest::binary>> = message
      
      rules = [{:red, "apples"}, "are"]
      are = mark_up("are")
      apples = mark_up("apples", :red)
      expected = apples <> " " <> are <> rest

      result = capture_io(fn -> Tester.log(message, mark_list: rules) end)
      assert String.ends_with?(result, expected <> "\n")
    end
    
    test "should allow regexes" do
      message = "apples are tasty"
      <<"apples", " ", "are", rest::binary>> = message
      rules = [{:red, ~r{(?i)APPLES?}}, "are"]
      are = mark_up("are")
      apples = mark_up("apples", :red)
      expected = apples <> " " <> are <> rest

      result = capture_io(fn -> Tester.log(message, mark_list: rules) end)
      assert String.ends_with?(result, expected <> "\n")
    end
    
    test "should highight more if found" do
      message = "apples are full of rippley goodness"
      <<"apples", " ", "are", _rest::binary>> = message
      rules = [{:cyan, ~r{(?i)[aeiou]p+LES?}}, "are"]
      are = mark_up("are")
      apples = mark_up("apples", :cyan)
      ripple = mark_up("ipple", :cyan)


      result = capture_io(fn -> Tester.log(message, mark_list: rules) end)
      assert result =~ apples
      assert result =~ ripple
      assert result =~ are
    end
    
    @tag skip_without_ansi()
    test "last should win" do
      message = "apples are full of rippley goodness"
      <<"apples", " ", "are", _rest::binary>> = message
      rules = [{:cyan, ~r{(?i)[aeiou]p+lES?}}, "are", {:magenta, "p"}]
      are = mark_up("are")
      apples = mark_up("apples", :cyan)
      ripple = mark_up("ipple", :cyan)
      p = mark_up("p", :magenta)

      result = capture_io(fn -> Tester.log(message, mark_list: rules) end)
      refute result =~ apples
      refute result =~ ripple
      assert result =~ are
      assert result =~ p
    end
    
    def mark_up(word, color \\ :yellow) do
      AnsiHelper.do_ansi(color)
      <> AnsiHelper.do_ansi(:reverse)
      <> word
      <> AnsiHelper.do_ansi(:reset)
    end
  end

  describe "should not use ansi when not enabled" do
    test "should not have ansi when not enabled" do
      if IO.ANSI.enabled?() do
        IO.puts("Warning, ansi is ENABLED, can't test not-enabled.")
      else
        assert has_no_ansi(&test_log/0)
      end
    end
  end

  describe "Debug" do
    test "should log" do
      assert_log(&test_debug/0)
    end
  end

  describe "basic usage" do

    @tag skip_without_ansi()
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
  end
  
  describe "idempotency" do
    test "should return message unchanged" do
      message = "hello world"
      assert_log_result(message, &test_log/0)
      assert_log_result(message, fn -> Tester.log(message) end)
      assert_log_result(message, fn -> Tester.debug(message) end)
      assert_log_result(message, fn -> Tester.mark(message) end)
      assert_log_result(message, fn -> Tester.log(message, mark_list: ["he"]) end)
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

  test "assert only accepts true" do
    assert true
  end

  test "refute only accepts false" do
    refute false
  end
end

