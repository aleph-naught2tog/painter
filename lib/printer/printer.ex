defmodule Printer do
  import AnsiHelper, only: [do_ansi: 1]

  def line(color, width \\ 80, char \\ "-") do
    "\n" <> do_ansi(color) <> across(width, char) <> do_ansi(:reset) <> "\n"
  end

  def with_line_break(string, where \\ :before) do
    case where do
      :before -> "\n" <> string
      _ -> string <> "\n"
    end
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
end

