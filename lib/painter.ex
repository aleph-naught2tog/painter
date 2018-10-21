# TODO: currently, when we have any options, 
#       we lose the pretty-print from inspect.

# TODO: "frame" for long stuff -- ie, long things get pushed to next line
#       and we have an open/close linein the color

defmodule Painter.Opts do
  defstruct color: :cyan,
            with_defaults: true,
            name: nil
end

defmodule Painter do
  import AnsiHelper

  @callback paint_color() :: atom
  @callback paint_name() :: binary

  @moduledoc """
  Documentation for Painter.
  """

  @spec format(message::any, color::atom, name::binary, opts::Keyword.t)::message::any
  def format(message, color, name, _opts) when is_binary(message) do
    do_color(name, color) <> " " <> message
  end

  def format(message, color, name, opts) do
    message
    |> inspect(pretty: true)
    |> format(color, name, opts)
  end
  
  @spec do_log_meta(name::binary, mode:: nil | atom)::binary
  @spec do_log_meta(name::binary)::binary
  defp do_log_meta(message, nil), do: do_log_meta(message)
  defp do_log_meta("Elixir." <> name, mode), do: do_log_meta(name, mode)

  defp do_log_meta(name, mode) do
    "[#{name}:#{mode}]"
  end
  
  defp do_log_meta("Elixir." <> name), do: do_log_meta(name)
  defp do_log_meta(name) do
    "[#{name}]"
  end
  
  @spec do_color(message::any, color::atom) :: binary
  defp do_color(message, color) when not is_binary(message) do
    do_color(inspect(message, pretty: true), color)
  end

  defp do_color(message, color) do
    chroma = do_ansi(color)
    reset = reset()
    chroma <> message <> reset
  end
  
  @spec do_label(message::any, label::nil | binary)::message::any
  def do_label(message, nil), do: message
  def do_label(message, label) when is_binary(message) do
    "#{label}: " <> message
  end

  def do_label(message, label) do
    do_label(inspect(message), label)
  end

  @spec get_filter(word::binary|Regex.t, color::atom|nil) :: (binary->binary)
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
  @type ident_of(x_type) :: (x::x_type->x::x_type)
  @spec prep_filter(nil) :: ident_of(binary)
  @spec prep_filter(list) :: (binary->binary)
  def prep_filter(nil), do: ident()
  def prep_filter(maybe_mark_list) do
    filters = maybe_mark_list
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

  @spec do_log(name::binary, color::atom, message::any, opts::list) :: message::any
  def do_log(name, color, message, opts \\ []) do
    maybe_label = Keyword.get(opts, :label)
    maybe_mode = Keyword.get(opts, :mode)
    maybe_reverse = Keyword.get(opts, :reverse)
    maybe_mark_list = Keyword.get(opts, :mark_list)
    prefix = Keyword.get(opts, :prefix, "")
    IO.inspect(prefix, label: "is nil? #{prefix === nil}")
    mark_filter = prep_filter(maybe_mark_list)

    header =
      name
      |> do_log_meta(maybe_mode)
      |> reverse(maybe_reverse)

    message
    |> do_label(maybe_label)
    |> Painter.format(color, header, opts)
    |> mark_filter.()
    |> IO.puts()

    message
  end

  @spec write(mod::module, message::any, opts::Keyword.t) :: message::any
  def write(mod, message, opts \\ []) do
    new_opts = Keyword.merge(opts, mode: :write)
    log(mod, message, new_opts)
  end
  
  def value(mod, message, opts \\ []) do
    log(mod, __ENV__, opts)
    log(mod, message, opts)
  end

  @spec debug(mod::module, message::any, opts::Keyword.t) :: message::any
  def debug(mod, message, opts \\ []) do
    new_opts = Keyword.merge(opts, mode: :debug)
    log(mod, message, new_opts)
  end

  @spec log(mod::module, message::any, opts::Keyword.t) :: message::any
  def log(mod, message, opts \\ []) do
    color = mod_color(mod)
    name = mod_name(mod)

    do_log(name, color, message, opts)
  end
  
  @spec mark(mod::module, message::any, opts::Keyword.t) :: message::any
  def mark(mod, message, opts \\ []) do
    new_opts =
      opts
      |> Keyword.merge(mode: :mark)
      |> Keyword.merge(reverse: true)

    log(mod, message, new_opts)
  end

  @spec error(mod::module, message::any, opts::Keyword.t) :: message::any
  def error(mod, message, opts \\ []) do
    new_opts =
      opts
      |> Keyword.merge(mode: :error)
      |> Keyword.merge(reverse: true)

    log(mod, message, new_opts)
  end

  @spec mod_color(mod :: module) :: atom
  defp mod_color(mod) do
    apply(mod, :paint_color, [])
  end

  @spec mod_name(mod :: module | binary) :: binary
  defp mod_name(mod) do
    if (is_binary(mod)) do
      apply(String.to_atom(mod), :paint_name, [])
    else
      apply(mod, :paint_name, [])
    end
  end
  
  def paint_color, do: :light_blue
  def paint_name, do: __MODULE__


  def parse({name, _, nil} = value, context) when is_atom(name) do
    type = "Variable"
    
  end
  def parse({:&, _, arguments} = value, context) do
    type = "Reference"
    {mod, {function_name, arity}, line_number} = context
    from = "#{mod}.#{function_name}/#{arity}"
    "\n#{type}"
  end
  def parse({local_call, _, arguments} = value, context) when is_atom(local_call) do
    type = "Local call"

    from = "#{}"

  end
  def parse({remote_call, _, arguments} = value, context) when is_tuple(remote_call) do
    type = "Remote call"

    from = "#{}"

  end
  def parse(value, context) do
    type = "Literal"

    from = "#{}"

  end
  
  def context(env) do
    {env.module, env.function, env.line}
  end

  defmodule Defaults do
    defmacro __using__(_) do
      caller = __CALLER__.module

      quote location: :keep do
        defmacro value(message) do  
          current_context = Painter.parse(message, Painter.context(__CALLER__))
          quote do
          end
        end
        
        def log(message, opts \\ []), do: Painter.log(unquote(caller), message, opts)
        def debug(message, opts \\ []), do: Painter.debug(unquote(caller), message, opts)
        def mark(message, opts \\ []), do: Painter.mark(unquote(caller), message, opts)
        def error(message, opts \\ []), do: Painter.error(unquote(caller), message, opts)
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

