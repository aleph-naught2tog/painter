defmodule Painter.Opts do
  defstruct color: :cyan,
            with_defaults: true,
            name: nil,
            width: 80,
            write_with_color: false

  def default_opts(false) do
    [
      pretty: true,
      # structs: true,
      # binaries: :infer,
      # charlists: :infer,
      # limit: 50,
      # printable_limit: 4096,
      # width: 80,
      # base: :decimal,
      safe: true
    ]
  end
  
  def default_opts(true) do
    Keyword.merge(default_opts(false), [syntax_colors: syntax_colors()])
  end

  def syntax_colors() do
    [
      number: :blue,
      atom: :magenta,
      regex: :green,
      tuple: :light_blue,
      map: :light_magenta,
      list: :yellow
    ]
  end
end

