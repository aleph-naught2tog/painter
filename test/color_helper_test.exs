defmodule Painter.ColorHelperTest do
  alias TestHelpers.ColorHelper
  import TestHelpers.ColorHelper

  use ExUnit.Case
  doctest ColorHelper, import: true

  describe "has_color binary" do
    test "should be true for strings of all right color" do
      message = IO.ANSI.red() <> "bianca"
      assert has_color(:red, message)
    end

    test "should be false for strings of all wrong color" do
      message = IO.ANSI.red() <> "bianca"
      refute has_color(:green, message)
    end

    test "should be true for strings with only some right color" do
      message = "pears" <> IO.ANSI.red() <> "bianca"
      assert has_color(:red, message)
    end

    test "should be false for strings with no color" do
      refute has_color(:red, "bianca")
    end
  end

  describe "has_color function" do
    test "should be true for strings of all right color" do
      message = IO.ANSI.red() <> "bianca"
      assert has_color(:red, fn -> IO.puts(message) end)
    end

    test "should be false for strings of all wrong color" do
      message = IO.ANSI.green() <> "bianca"
      refute has_color(:red, fn -> IO.puts(message) end)
    end

    test "should be true for strings with only some right color" do
      message = "pears" <> IO.ANSI.red() <> "bianca"
      assert has_color(:red, fn -> IO.puts(message) end)
    end

    test "should be false for strings with no color" do
      refute has_color(:red, fn -> IO.puts("beep") end)
    end
  end

  describe "has_any_ansi binary" do
    test "should be true for strings with any ansi" do
      assert has_any_ansi("pears" <> IO.ANSI.red() <> "apples")
    end

    test "Should be true for all-colored strings" do
      assert has_any_ansi(IO.ANSI.red() <> "apples")
    end

    test "should be false for plain strings" do
      refute has_any_ansi("apples")
    end
  end

  describe "has_any_ansi function" do
    test "should be true for strings with any ansi" do
      assert has_any_ansi(fn -> IO.puts("pears" <> IO.ANSI.red() <> "apples")end)
    end

    test "Should be true for all-colored strings" do
      assert has_any_ansi(fn -> IO.puts(IO.ANSI.red() <> "apples")end)
    end

    test "should be false for plain strings" do
      refute has_any_ansi(fn -> IO.puts("apples")end)
    end
  end

  describe "has_no_ansi binary" do
    test "should be true for plain strings" do
      assert has_no_ansi("apples")
    end

    test "should be false for colored strings" do
      refute has_no_ansi(IO.ANSI.red() <> "apples")
    end

    test "should be false for ansi anywhere in string" do
      refute has_no_ansi("pears" <> IO.ANSI.red() <> "apples")
    end
  end

  describe "has_no_ansi function" do
    test "should be true for plain strings" do
      assert has_no_ansi(fn -> IO.puts("apples") end)
    end

    test "should be false for colored strings" do
      refute has_no_ansi(fn -> IO.puts(IO.ANSI.red() <> "apples") end)
    end

    test "should be false for ansi anywhere in string" do
      refute has_no_ansi(fn -> IO.puts("pears" <> IO.ANSI.red() <> "apples") end)
    end
  end
end