defmodule Painter do
  import AnsiHelper
  import Painter.Opts

  use Application

  @impl true
  def start(_, _) do
    unless IO.ANSI.enabled?() do
      IO.puts("(Painter) Your current settings show that your device is *not* ANSI-enabled.")

      if Application.get_env(:painter, :ansi_enabled) do
        IO.puts("\t...but your config says to enable ANSI.")
        IO.puts("\n\tWe've enabled ANSI for Painter, but nothing else.")
        IO.puts("\t(If you have questions, check out the README.)\n")
      end
    end

    {:ok, self()}
  end

  @callback paint_color() :: atom
  @callback paint_name() :: binary
  @callback init_opts() :: Painter.Opts
  @callback init_opts(atom | binary) :: any

  @moduledoc """
  Documentation for Painter.
  """

  @spec local_inspect(message :: any, inspect_opts :: Keyword.t()) :: binary
  def local_inspect(message, inspect_opts \\ []) do
    defaults = default_opts(Keyword.get(inspect_opts, :should_color, should_color?()))
    opts = Keyword.merge(defaults, inspect_opts)
    inspect(message, opts)
  end

  def should_color?() do
    case Application.get_env(:painter, :ansi_enabled) do
      nil -> IO.ANSI.enabled?()
      true -> true
      false -> false
    end
  end

  @spec format(message :: any, name :: binary, opts :: Keyword.t()) :: message :: any
  def format(message, name, opts \\ [])
  def format("", _, _), do: gray("<EMPTY_STRING>")
  def format(<<0>>, _, _), do: gray("<NULL_BYTE>")
  def format(message, _, _) when is_binary(message), do: message

  def format(message, name, opts) do
    message
    |> local_inspect(opts)
    |> format(name)
  end
  
  defp gray(message) do
    if should_color?() do
      do_color(message, [2,2,2])
    else
      message
    end
  end

  @spec do_color(message :: any, color :: atom) :: binary
  defp do_color(message, color) when not is_binary(message) do
    do_color(local_inspect(message), color)
  end

  defp do_color(message, color) do
    chroma = do_ansi(color)
    reset = reset()
    chroma <> message <> reset
  end

  @spec get_filter(word :: binary | Regex.t(), color :: atom | nil) :: (binary -> binary)
  def get_filter(word, color \\ :yellow)

  def get_filter(word, color) when is_binary(word) do
    escaped = Regex.escape(word)

    case Regex.compile(escaped) do
      {:ok, regex} -> get_filter(regex, color)
      _ -> ident()
    end
  end

  def get_filter(maybe_regex, color) do
    if Regex.regex?(maybe_regex) do
      f_string = do_ansi(color) <> do_ansi(:reverse)
      color_fun = fn word -> f_string <> word <> reset() end
      &Regex.replace(maybe_regex, &1, color_fun)
    else
      ident()
    end
  end

  def ident, do: fn x -> x end
  @type ident_of(x_type) :: (x :: x_type -> x :: x_type)

  @spec prep_filter(nil) :: ident_of(binary)
  @spec prep_filter(list) :: (binary -> binary)

  def prep_filter(nil), do: ident()

  def prep_filter(maybe_mark_list) do
    filters =
      maybe_mark_list
      |> Enum.map(fn current ->
        case current do
          {color, target} -> get_filter(target, color)
          w -> get_filter(w)
        end
      end)

    fn str ->
      Enum.reduce(filters, str, fn current_fun, str_so_far -> current_fun.(str_so_far) end)
    end
  end

  def label_for([]), do: ""

  def label_for(opts) do
    case Keyword.get(opts, :label) do
      nil -> ""
      label -> "#{label}: "
    end
  end

  def mode_for([]), do: ""

  def mode_for(opts) do
    case Keyword.get(opts, :mode) do
      nil -> ""
      mode -> ":#{mode}"
    end
  end

  @spec do_log(name :: binary, color :: atom, message :: any, opts :: list) :: message :: any
  def do_log(name, color, message, opts \\ [])

  def do_log(name, :none, message, opts) do
    prefix = Keyword.get(opts, :prefix, "")
    suffix = Keyword.get(opts, :suffix, "")
    device = Keyword.get(opts, :device, :stdio)

    label = label_for(opts)
    mode = mode_for(opts)

    log_name =
      if String.starts_with?(name, "Elixir.") do
        String.trim_leading(name, "Elixir.")
      else
        name
      end

    header = "[#{log_name}#{mode}]"

    text = Painter.format(message, header, opts)

    final = "#{header} #{label}#{prefix}#{text}#{suffix}"
    IO.puts(device, final)

    message
  end

  def do_log(name, color, message, opts) do
    prefix = Keyword.get(opts, :prefix, "")
    suffix = Keyword.get(opts, :suffix, "")
    device = Keyword.get(opts, :device, :stdio)

    label = label_for(opts)
    mode = mode_for(opts)

    log_name =
      if String.starts_with?(name, "Elixir.") do
        String.trim_leading(name, "Elixir.")
      else
        name
      end

    should_reverse? = Keyword.get(opts, :reverse)
    header = reverse("[#{log_name}#{mode}]", should_reverse?)

    text = Painter.format(message, header, opts)

    maybe_mark_list = Keyword.get(opts, :mark_list)
    mark_filter = prep_filter(maybe_mark_list)
    highlighted_text = mark_filter.(text)

    final = "#{do_color(header, color)} #{label}#{prefix}#{highlighted_text}#{suffix}"
    IO.puts(device, final)

    message
  end

  @spec write(mod :: module, message :: any, opts :: Keyword.t()) :: message :: any
  def write(mod, message, opts \\ []) do
    write_opts = Keyword.get(opts, :write_opts, [:append])
    filepath = Keyword.get(opts, :path, default_day())

    write_with_color = apply(mod, :init_opts, [:write_with_color])

    opts =
      if write_with_color or Keyword.get(opts, :force) do
        opts
      else
        opts
        |> Keyword.put_new(:should_color, false)
        |> Keyword.put(:color_override, :none)
      end

    {:ok, device} = File.open(filepath, write_opts)
    opts = Keyword.merge(opts, device: device)
    log(mod, message, opts)
    File.close(device)
  end

  def default_day do
    date =
      Date.utc_today()
      |> to_string()
      |> String.replace("-", "_")

    date <> ".log"
  end

  @spec debug(mod :: module, message :: any, opts :: Keyword.t()) :: message :: any
  def debug(mod, message, opts \\ []) do
    new_opts = Keyword.merge(opts, mode: :debug)
    log(mod, message, new_opts)
  end

  @spec log(mod :: module, message :: any, opts :: Keyword.t()) :: message :: any
  def log(mod, message, opts \\ []) do
    color = Keyword.get(opts, :color_override, mod_color(mod))
    name = mod_name(mod)

    cond do
      Keyword.get(opts, :force) -> do_log(name, color, message, opts)
      Keyword.get(opts, :no_color) -> do_log(name, :none, message, opts)
      should_color?() -> do_log(name, color, message, opts)
      true -> do_log(name, :none, message, opts)
    end
  end

  @spec mark(mod :: module, message :: any, opts :: Keyword.t()) :: message :: any
  def mark(mod, message, opts \\ []) do
    new_opts =
      opts
      |> Keyword.merge(mode: :mark)
      |> Keyword.merge(reverse: true)

    log(mod, message, new_opts)
  end

  @spec error(mod :: module, message :: any, opts :: Keyword.t()) :: message :: any
  def error(mod, message, opts \\ []) do
    new_opts =
      opts
      |> Keyword.merge(mode: :error)

    do_log(mod_name(mod), :red, message, new_opts)
  end

  @spec mod_color(mod :: module) :: atom
  defp mod_color(mod) do
    apply(mod, :paint_color, [])
  end

  @spec mod_name(mod :: module | binary) :: binary
  defp mod_name(mod) do
    if is_binary(mod) do
      apply(String.to_atom(mod), :paint_name, [])
    else
      apply(mod, :paint_name, [])
    end
  end

  def paint_color, do: :light_blue
  def paint_name, do: Atom.to_string(__MODULE__)

  def pretty(env, {type, value}, indent \\ 2) do
    import Inspect.Algebra
    br = break("\n")

    file = Path.relative_to(env.file, System.cwd())
    {mod, {function_name, arity}, line_number} = {env.module, env.function, env.line}

    "Elixir." <> name = Atom.to_string(mod)
    from_doc = concat([name, ".", to_string(function_name), "/", to_string(arity)])

    br
    |> concat("├── ")
    |> concat(type)
    |> concat(": ")
    |> concat(Macro.to_string(value))
    |> concat(br)
    |> concat("└── ")
    |> concat(from_doc)
    |> concat(" - #{file}:#{line_number}")
    |> nest(indent)
    |> group()
    |> Inspect.Algebra.format(0)
    |> IO.iodata_to_binary()
  end
  
  def do_warn(message) do
    if should_color?() do
      IO.puts(:stderr, do_color(message, :yellow))
    else
      IO.puts(:stderr, message)
    end
  end
  
  def do_error(message) do
    if should_color?() do
      IO.puts(:stderr, do_color(message, :red))
    else
      IO.puts(:stderr, message)
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

      import Painter, only: [do_warn: 1, do_error: 1]
      
      @impl true
      def init_opts(), do: unquote(Macro.escape(init_opts))

      @impl true
      def init_opts(key) when is_binary(key), do: init_opts(String.to_atom(key))

      def init_opts(key) when is_atom(key) do
        Map.get(init_opts(), key, :no_such_key)
      end

      unquote(
        if with_defaults do
          quote do
            use Painter.Defaults
          end
        end
      )

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

