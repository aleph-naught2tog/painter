defmodule TestHelpers.ColorHelper do
  import ExUnit.CaptureIO

  @spec has_color(target_color::atom, io_function::fun) :: boolean
  def has_color(target_color, io_function) when is_function(io_function) do
    result = capture_io(io_function)
    has_color(target_color, result)
  end

  @spec has_color(target_color::atom, result::binary) :: boolean
  def has_color(target_color, result) when is_binary(result) do
    ansi_color = apply(IO.ANSI, target_color, [])
    (inspect result) =~ ansi_color
  end

  @spec all_colored(target_color::atom, io_function::fun) :: boolean
  def all_colored(target_color, io_function) when is_function(io_function) do
    result = capture_io(io_function)
    all_colored(target_color, result)
  end

  @spec all_colored(target_color::atom, result::binary) :: boolean
  def all_colored(target_color, result) when is_binary(result) do
    regex = all_colored_regex(target_color, result)
    (inspect result) =~ regex
  end

  @spec has_any_ansi(io_function::fun) :: boolean
  def has_any_ansi(io_function) when is_function(io_function) do
    result = capture_io(io_function)
    has_any_ansi(result)
  end

  @doc ~S"""

    iex> has_any_ansi("oranges")
    false

    iex> has_any_ansi(IO.ANSI.blue() <> "apples")
    true

  """
  @spec has_any_ansi(message::binary) :: boolean
  def has_any_ansi(message) when is_binary(message) do
    ansi_regex = ~r{(?<!\\)\\e\[\d+m}
    (inspect message) =~ ansi_regex
  end

  @doc ~S"""

      iex> message = "potatoes"
      iex> has_no_ansi(message)
      true

      iex> message = IO.ANSI.red() <> "hello world"
      iex> has_no_ansi(message)
      false

      iex> message = "potatoes"
      iex> message_writer = fn -> IO.puts(message) end
      iex> has_no_ansi(message_writer)
      true

      iex> message = IO.ANSI.red() <> "hello world"
      iex> message_writer = fn -> IO.puts(message) end
      iex> has_no_ansi(message_writer)
      false

  """
  @spec has_no_ansi(message::binary) :: boolean
  def has_no_ansi(message) when is_binary(message) do
    has_ansi? = has_any_ansi(message)
    !has_ansi?
  end

  @spec has_no_ansi(io_function::fun) :: boolean
  def has_no_ansi(io_function) when is_function(io_function) do
    has_ansi? = has_any_ansi(io_function)
    !has_ansi?
  end

  @doc ~S"""
  Creates a regex for testing whether a string is completely colored or not.

  ## Examples

      iex> regex = TestHelpers.ColorHelper.all_colored_regex(:red, "apples")
      iex> message = IO.ANSI.red() <> "apples"
      iex> Regex.match?(regex, message)
      true

      iex> regex = TestHelpers.ColorHelper.all_colored_regex(:green, "apples")
      iex> message = IO.ANSI.red() <> "apples"
      iex> Regex.match?(regex, message)
      false

  """
  @spec all_colored_regex(color::atom, message::binary) :: %Regex{}
  def all_colored_regex(color, message) do
    color_string = apply(IO.ANSI, color, [])
    escaped_color_string = Regex.escape(color_string)
    ~r/^#{escaped_color_string <> message}$/
  end
end
