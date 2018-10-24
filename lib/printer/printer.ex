defmodule Printer do

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
end