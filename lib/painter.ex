defmodule Painter do
  @callback log(message::any | binary) :: any

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

  defp get_header(color, name, opts \\ [])
  defp get_header(color, name, mode: mode) when is_atom(mode),
    do: get_header(color, name, Atom.to_string(mode))
  defp get_header(color, name, mode: mode) when is_binary(mode) do
    get_header(color, "[#{name}:#{mode}]")
  end
  defp get_header(color, name, _opts) do
    color_start = apply(IO.ANSI, color, [])
    reset = IO.ANSI.reset()
    color_start <> "[#{name}] " <> reset
  end

  def log(message, opts \\ [])
  def log(message, mode: mode) when is_atom(mode) do
    message
    |> Painter.format(:default_color, "[?]", mode: mode)
    |> IO.puts()

    message
  end

  def log(message, label: label) do
    log("#{label}: " <> inspect(message))

    message
  end

  def log(message, opts) do
    message
    |> Painter.format(:default_color, "[?]", opts)
    |> IO.puts()

    message
  end

  def debug(variable) do
    quote do
      unquote(variable)
      |> Macro.decompose_call()
      |> IO.inspect()
      log(unquote(variable), mode: :debug)
    end
  end

  defoverridable [log: 2]

  defmacro __using__(color: color, name: name) do
    quote do
      def safe_raise(error), do: raise(error)

      def log(message, opts \\ []) do
        message
        |> Painter.format(unquote(color), unquote(name), opts)
        |> IO.puts()

        message
      end
    end
  end
end
