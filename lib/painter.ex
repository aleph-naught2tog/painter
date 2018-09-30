defmodule Painter do
  @moduledoc """
  Documentation for Painter.
  """

  def format(message, color, name) when is_binary(message) do
    apply(IO.ANSI, color, [])
    |> Kernel.<>("[#{name}] ")
    |> Kernel.<>(IO.ANSI.reset())
    |> Kernel.<>(message)
  end

  def format(message, color, name) do
    message
    |> inspect(pretty: true)
    |> format(color, name)
  end

  defmacro __using__(color: color, name: name) do
    quote do
      def log(message, label: label), do: log(message, label)

      def log(message) do
        message
        |> Painter.format(unquote(color), unquote(name))
        |> IO.puts()

        message
      end

      def log(message, label) do
        log("#{label}: " <> inspect(message))

        message
      end
    end
  end
end
