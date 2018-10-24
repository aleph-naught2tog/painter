defmodule Painter.Opts do
  defstruct color: :cyan,
            with_defaults: true,
            name: nil,
            width: 80

  # todo: add -- default values to flag, verbosity, etc
end