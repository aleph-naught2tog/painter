defmodule Painter.Opts do
  defstruct [
    color: :default_color,
    with_defaults: true,
    name: nil,
  ]
end

defmodule Painter do
  @callback __color__::atom
  @callback __name__::binary

  @color &Painter.__color__/0
  @name &Painter.__name__/0

  @moduledoc """
  Documentation for Painter.
  """
#  def format(message, color, name, opts \\ [])
#  def format(message, color, name, opts) when is_binary(message) do
#    get_header(color, name, opts) <> message
#  end
#
#  def format(message, color, name, opts) do
#    message
#    |> inspect(pretty: true)
#    |> format(color, name, opts)
#  end
#
#  defp get_header(color, name, opts) do
#    name
#    |> do_log_meta(opts)
#    |> do_color(color)
#    |> do_opts(opts)
#  end
#
#  defp do_opts(value, opts) do
#    Enum.reduce(
#      opts,
#      value,
#      fn
#        (current, tuple_value) when is_tuple(tuple_value) ->
#          handle_opt("~~#{current}", tuple_value)
#        (_,_) -> "#{value}"
#      end
#    )
#  end
#
#  defp handle_opt(header, {key, value}) do
#    case key do
#      :label -> "#{header} #{value}:"
#      _ -> header
#    end
#  end
#
#  def safe_raise(error), do: raise error
#
#  defp do_log_meta(name, mode: mode) do
#    "[#{name}:#{mode}] "
#  end
#
#  defp do_log_meta(name, _) do
#    "[#{name}] "
#  end
#
#  defp do_color(string, color) do
#    chroma = apply(IO.ANSI, color, [])
#    reset = apply(IO.ANSI, :reset, [])
#    chroma <> string <> reset
#  end
#
#  def do_label(message, label) do
#    "#{label}: " <> inspect(message)
#  end

#  def log(message, opts \\ []) do
#    maybe_label = Keyword.get(opts, :label)
#    maybe_mode = Keyword.get(opts, :mode)
#
#    final_message =
#      case maybe_label do
#        nil -> message
#        _ -> do_label(message, maybe_label)
#      end
#
#    header =
#      case maybe_mode do
#        nil -> @name
#        _ -> do_log_meta(@name, mode: maybe_mode)
#      end
#
#    final_message
#    |> Painter.format(@color, header, opts)
#    |> IO.puts()
#
#    message
#  end

#  def debug(variable) do
#    log(variable, mode: :debug)
#  end
#
#  def debug(variable, opts) do
#    log(variable, [opts | {:mode, :debug}])
#  end

  def log(message), do: "message"

  defmodule Defaults do
    defmacro __using__(_) do
      quote do
        import Painter
      end
    end
  end

  defmacro __using__(init_opts \\ [])
  defmacro __using__(list_opts) do
    IO.inspect(list_opts, label: "init_opts before parse")

    init_opts =
      unless Keyword.get(list_opts, :name) do
        temp_opts = struct(Painter.Opts, list_opts)
        %{temp_opts | name: Atom.to_string(__CALLER__.module)}
      else
        struct(Painter.Opts, list_opts)
      end

    chosen_color = init_opts.color
    chosen_name = init_opts.name
    with_defaults = init_opts.with_defaults

    quote do
      @behaviour Painter

      unquote(if with_defaults do
        quote do
          use Painter.Defaults
        end
      end)

      @impl true
      def __color__ do
        unquote(chosen_color)
      end

      @impl true
      def __name__ do
        unquote(chosen_name)
      end

      defoverridable(Painter)
    end
  end
end
