defmodule Painter do
  @callback paint_color :: atom
  @callback paint_name :: binary

  @moduledoc """
  Documentation for Painter.
  """
  def format(message, color, name, opts \\ [])
  def format(message, color, name, opts) when is_binary(message) do
    get_header(color, name, opts) <> message
  end

  def format(message, color, name, opts) do
    message
    |> inspect(pretty: true)
    |> format(color, name, opts)
  end

  defp get_header(color, name, opts) do
    name
    |> do_log_meta(opts)
    |> do_color(color)
    |> do_opts(opts)
  end

  defp do_opts(value, opts) do
    Enum.reduce(
      opts,
      value,
      fn
        (current, tuple_value) when is_tuple(tuple_value) ->
          handle_opt("~~#{current}", tuple_value)
        (_,_) -> "#{value}"
      end
    )
  end

  defp handle_opt(header, {key, value}) do
    case key do
      :label -> "#{header} #{value}:"
      _ -> header
    end
  end

  defp if_pipe(value, condition_func, do: do_block), do: if_pipe(value, condition_func, do: do_block, else: fn ident -> ident end)
  defp if_pipe(value, condition_func, do: do_block, else: else_block) do
    if condition_func.(value) do
      do_block.(value)
    else
      else_block.(value)
    end
  end

  defp do_log_meta(name, mode: mode) do
    "[#{name}:#{mode}] "
  end

  defp do_log_meta(name, _) do
    "[#{name}] "
  end

  defp do_color(string, color) do
    chroma = apply(IO.ANSI, color, [])
    reset = apply(IO.ANSI, :reset, [])
    chroma <> string <> reset
  end

  def log(message, opts \\ [])
  def log(message, mode: mode) when is_atom(mode) do
    message
    |> Painter.format(paint_color(), paint_name(), mode: mode)
    |> IO.puts()

    message
  end

  def log(message, label: label) do
    log("#{label}: " <> inspect(message))

    message
  end

  def log(message, opts) do
    message
    |> Painter.format(paint_color(), paint_name(), opts)
    |> IO.puts()

    message
  end

  def debug(variable) do
    log(variable, mode: :debug)
  end

  def debug(variable, opts) do
    log(variable, [opts | {:mode, :debug}])
  end

  def paint_color(), do: :cyan
  def paint_name(), do: "?"

  defoverridable [log: 2, paint_color: 0, paint_name: 0]

  defmacro __using__(color: color, name: name) do
    quote do
      def safe_raise(error), do: raise(error)

      def log(message, opts \\ []) do
        message
        |> Painter.format(paint_color(), paint_name(), opts)
        |> IO.puts()

        message
      end

      def paint_color, do: unquote(color)
      def paint_name, do: unquote(name)
    end
  end
end
