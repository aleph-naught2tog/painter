defmodule Painter do
  @moduledoc """
  Documentation for Painter.
  """
  @spec format(binary, atom, binary) :: binary
  def format(message, color, name) when is_binary(message) do
    get_header(color, name) <> message
  end

  @spec format(any, atom, binary) :: binary
  def format(message, color, name) do
    message
    |> inspect(pretty: true)
    |> format(color, name)
  end

  @spec get_header(atom, binary) :: binary
  defp get_header(color, name) do
    color_start = apply(IO.ANSI, color, [])
    reset = IO.ANSI.reset()
    color_start <> "[#{name}]" <> reset
  end

  defmacro __using__(color: color, name: name) do
    quote do
      def safe_raise(error), do: raise(error)

      @spec log(binary, label: binary) :: binary
      def log(message, label: label), do: log(message, label)

      @spec log(any) :: any
      def log(message) do
        message
        |> Painter.format(unquote(color), unquote(name))
        |> IO.puts()

        message
      end

      @spec log(any, binary) :: any
      def log(message, label) do
        log("#{label}: " <> inspect(message))

        message
      end
    end
  end
end
