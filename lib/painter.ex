defmodule Painter.Opts do
  defstruct [
    color: :default_color,
    with_defaults: true,
    name: nil,
  ]
end

defmodule Painter do
  @callback paint_color()::atom
  @callback paint_name()::binary

  @moduledoc """
  Documentation for Painter.
  """

  def format(message, color, name, _opts) when is_binary(message) do
    do_color(name, color) <> " " <> message
  end

  def format(message, color, name, opts) do
    message
    |> inspect(pretty: true)
    |> format(color, name, opts)
  end

  defp do_log_meta("Elixir." <> name, mode: mode), do: do_log_meta(name, mode: mode)
  defp do_log_meta(name, mode: mode) do
    "[#{name}:#{mode}]"
  end

  defp do_log_meta("Elixir." <> name), do: do_log_meta(name)
  defp do_log_meta(name) do
    "[#{name}]"
  end

  defp do_color(string, color) when not is_binary(string) do
    do_color(inspect(string, pretty: true), color)
  end

  defp do_color(string, color) do
    chroma = apply(IO.ANSI, color, [])
    reset = apply(IO.ANSI, :reset, [])
    chroma <> string <> reset
  end

  def do_label(message, label) when is_binary(message) do
    "#{label}: " <> message
  end

  def do_label(message, label) do
    do_label(inspect(message), label)
  end

  def do_log(name, color, message, opts \\ []) do
    maybe_label = Keyword.get(opts, :label)
    maybe_mode = Keyword.get(opts, :mode)
    maybe_reverse = Keyword.get(opts, :reverse)

    final_message =
      case maybe_label do
        nil -> message
        _ -> do_label(message, maybe_label)
      end

    header =
      maybe_mode
      |> case do
        nil -> do_log_meta(name)
        _ -> do_log_meta(name, mode: maybe_mode)
      end
      |> (&if (maybe_reverse !== nil) do
        IO.ANSI.reverse()
        |> Kernel.<>(&1)
      else
        &1
      end).()

    final_message
    |> Painter.format(color, header, opts)
    |> IO.puts()

    message
  end

  def debug(mod, message, opts \\ []) do
    new_opts = Keyword.merge(opts, [mode: :debug])
    log(mod, message, new_opts)
  end

  def log(mod, message, opts \\ []) do
    color = mod_color(mod)
    name = mod_name(mod)

    do_log(name, color, message, opts)
  end

  def mark(mod, message, opts \\ []) do
    new_opts =
      opts
      |> Keyword.merge([mode: :mark])
      |> Keyword.merge([reverse: true])

    log(mod, message, new_opts)
  end

  defp mod_color(mod) do
    apply(mod, :paint_color, [])
  end

  defp mod_name(mod) do
    apply(mod, :paint_name, [])
  end

  defmodule Defaults do
    defmacro __using__(_) do
      caller = __CALLER__.module
      quote do
        def log(message), do: Painter.log(unquote(caller), message)
        def log(message, opts), do: Painter.log(unquote(caller), message, opts)

        def debug(message), do: Painter.debug(unquote(caller), message)
        def debug(message, opts), do: Painter.debug(unquote(caller), message, opts)

        def mark(message), do: Painter.mark(unquote(caller), message)
        def mark(message, opts), do: Painter.mark(unquote(caller), message, opts)
      end
    end
  end

  defmacro __using__(init_opts \\ [])
  defmacro __using__(list_opts) do
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
      def paint_color do
        unquote(chosen_color)
      end

      @impl true
      def paint_name do
        unquote(chosen_name)
      end

      defoverridable(Painter)
    end
  end
end
