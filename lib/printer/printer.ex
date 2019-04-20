defmodule Printer do
  import AnsiHelper, only: [do_ansi: 1]
  import Inspect.Algebra

  def linebreak, do: break("\n")

  def do_indent(value, opts, level \\ 2) do
    linebreak()
    |> concat(to_doc(value, struct(Inspect.Opts, opts)))
    |> nest(level)
    |> group()
    |> format(0)
    |> IO.iodata_to_binary()
    |> String.replace(~r{^(\s++)"}, "\\1")
    |> String.trim_trailing("\"")
  end

  def line(color, width \\ 80, char \\ "-") do
    linebreak()
    |> concat(do_ansi(color))
    |> concat(across(width, char))
    |> concat(do_ansi(:reset))
    |> concat(linebreak())
    |> format(80)
    |> IO.iodata_to_binary()
  end

  def with_line_break(string, :before) do
    linebreak()
    |> concat(string)
    |> format(80)
    |> IO.iodata_to_binary()
  end

  def with_line_break(string, _) do
    string
    |> concat(linebreak())
    |> format(80)
    |> IO.iodata_to_binary()
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

  def pretty(env, raw_message, indent \\ 2) do
    import Inspect.Algebra
    {type, value} = parse(raw_message)
    br = break("\n")

    file = Path.relative_to(env.file, File.cwd())
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

  def line_glue(first, second) do
    glue(first, linebreak(), second)
  end
end

