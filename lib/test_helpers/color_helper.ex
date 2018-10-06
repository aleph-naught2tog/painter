defmodule TestHelpers.ColorHelper do
  import ExUnit.CaptureIO

  @spec has_color(target_color::atom, io_function::fun) :: boolean
  def has_color(target_color, io_function) when is_function(io_function) do
    result = capture_io(io_function)
    has_color(target_color, result)
  end

  @spec has_color(target_color::atom, result::binary) :: boolean
  def has_color(target_color, result) when is_binary(result) do
    color_string = apply(IO.ANSI, target_color, [])
    escaped_color_string = Regex.escape(color_string)
    result =~ ~r/#{escaped_color_string}/
  end

  @spec has_any_ansi(io_function::fun) :: boolean
  def has_any_ansi(io_function) when is_function(io_function) do
    result = capture_io(io_function)
    has_any_ansi(result)
  end

  @doc ~S"""

  ## Examples

    iex> has_any_ansi(IO.ANSI.blue() <> "apples")
    true

  """
  @spec has_any_ansi(message::binary) :: boolean
  def has_any_ansi(message) when is_binary(message) do
    ansi_regex = ~r{(?<!\\)\\e\[\d+m}
    (inspect message) =~ ansi_regex
  end

  @doc ~S"""

  ## Examples

      iex> message = IO.ANSI.red() <> "hello world"
      iex> has_no_ansi(message)
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
end
