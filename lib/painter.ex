defmodule Painter.Opts do
  defstruct color: :cyan,
            with_defaults: true,
            name: nil,
            width: 80
  # todo: add -- default values to flag, verbosity, etc
end

defmodule Hooks do
  def teeniest_c do
    ~S"""
    #include <unistd.h>
    #include <stdio.h>
    
    int main(void) 
    {      
      if (isatty(STDOUT_FILENO)) 
      {
        puts("true");
      } 
      else 
      {
        puts("false");
      }
      
      return 0;
    }
    """
  end
  
  defmacro __before_compile__(_) do
    tmp_dir = System.tmp_dir()
    filename = tmp_dir <> "isatty.c"
    binname = "isatty"
    binpath = tmp_dir <> binname
    
    File.rm(filename)
    File.rm(binpath)
    
    unless File.exists?(binpath) do
      result = File.open(filename, [:write], fn file -> 
        case IO.write(file, teeniest_c()) do
          :ok -> System.cmd("gcc", [filename, "-o", binpath])
        end
      end)
      
      case result do
        {:ok, {_, 0}} -> System.cmd(binpath, [])
        _ -> IO.inspect(result, label: "FAIL")
      end
    end

    quote location: :keep do
      def isatty() do
        case System.cmd(unquote(binpath), []) do
          {:ok, {isatty?, 0}} -> String.to_existing_atom(isatty?)
          _ -> false
        end
      end
    end
  end
end

defmodule Painter do
  import AnsiHelper
  
  @before_compile Hooks

  @callback paint_color() :: atom
  @callback paint_name() :: binary

  @moduledoc """
  Documentation for Painter.
  """

  @spec local_inspect(message::any, inspect_opts:: Keyword.t) :: binary
  def local_inspect(message, inspect_opts \\ []) do
    default_opts = [pretty: true]
    inspect(message, Keyword.merge(default_opts, inspect_opts))
  end

  @spec format(message::any, color::atom, name::binary, opts::Keyword.t)::message::any
  def format(message, color, name, opts \\ [])
  def format("",_,_,_), do: "<EMPTY_STRING>"
  def format(<<0>>,_,_,_), do: "<NULL_BYTE>"
  def format(message,_,_,_) when is_binary(message), do: message
  def format(message, color, name, opts) do
    message
    |> local_inspect(opts)
    |> format(color, name)
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
  
  @spec do_log(name::binary, color::atom, message::any, opts::list) :: message::any
  def do_log(name, color, message, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    suffix = Keyword.get(opts, :suffix, "")
    device = Keyword.get(opts, :device, :stdio)
    
    label = label_for(opts)
    mode = mode_for(opts)
    
    log_name = String.trim_leading(name, "Elixir.")
    should_reverse? = Keyword.get(opts, :reverse)
    header = reverse("[#{log_name}#{mode}]", should_reverse?)

    text = Painter.format(message, color, header, opts)
    
    maybe_mark_list = Keyword.get(opts, :mark_list)
    mark_filter = prep_filter(maybe_mark_list)
    highlighted_text = mark_filter.(text)
    
    final = "#{do_color(header, color)} #{label}#{prefix}#{highlighted_text}#{suffix}"
    IO.puts(device, final)

    message
  end

  @spec write(mod::module, message::any, opts::Keyword.t) :: message::any
  def write(mod, message, path \\ :default_day, write_opts \\ [:append], opts \\ []) do
    filepath = if(path === :default_day, do: default_day(), else: path)
    
    File.open(filepath, write_opts, fn 
      {:ok, device} -> 
        new_opts = Keyword.merge(opts, device: device)
        spawn(fn -> 
          # change stdio
          Process.group_leader(self(), device)
          log(mod, message, new_opts)
        end)
      _ -> message
    end)
  end
  
  def default_day do
    date = Date.utc_today() 
    |> to_string() 
    |> String.replace("-", "_")
    
    date <> ".log"
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

  def parse({name, _, nil} = value) when is_atom(name) do
    {"variable", value}
  end
  
  def parse({:&, _, _arguments} = value) do
    {"reference", value}
  end

  def parse({local_call, _, _arguments} = value) when is_atom(local_call) do
    {"local call", value}
  end
  
  def parse({remote_call, _, _arguments} = value) when is_tuple(remote_call) do
    {"remote call", value}
  end
  
  def parse(value) do
    {"literal", value}
  end
  
  def across(width, how \\ :evenly, char \\ "-") do
    times = 
      if how === :evenly do
        div(width, String.length(char))
      else
        width
      end
    
    String.duplicate(char, times)
  end
  
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
    |> format(0)
    |> IO.iodata_to_binary()
  end

  defmodule Defaults do
    defmacro __using__(_) do
      caller = __CALLER__.module
      quote location: :keep do
        defmacro detail(message, opts \\ []) do
          indent = 2
          footer = Painter.pretty(__CALLER__, Painter.parse(message), indent)
          quote do
            line = "\n" <> do_ansi(paint_color()) <> Painter.across(80) <> do_ansi(:reset) <> "\n"
            prefix = "\n" <> String.duplicate(" ", unquote(indent))
            suffix = unquote(footer) <> line
            new_opts = Keyword.merge([suffix: suffix, prefix: prefix], unquote(opts))
            log(unquote(message), new_opts)
          end
        end
        
        def write(message, path \\ :default_day, opts \\ []), do: Painter.write(unquote(caller), message, path, opts)
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
