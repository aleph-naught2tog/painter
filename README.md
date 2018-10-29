# Painter

Painter tries to bring some fancy and eye candy to your terminal -- without
wrecking the legibility of any log files. Concurrency in Elixir is great, but
means that reading logs can be hard when multiple processes are sharing a view.
With Painter, you can color-coordinate logging, as well as highlight key words
inside the text being output itself.

## Config

### Enabling/Disabling Colors
While you can always override it by calling the `IO.ANSI` functions yourself,
it's nice to not worry about that every time. *All of Painter's settings about
ANSI only affect Painter's calls.* You can disable ANSI globally, but allow
Painter to emit codes; likewise, you can allow ANSI everywhere, but disable it
for Painter.

The most "local" rule wins. If Elixir detects that ANSI should be enabled, and
you disable it for Painter in your config file -- the config file wins.

By default, Painter will follow the following rules for outputting ANSI codes.
* `Painter.write` -- intended to be used with normal files vs. something like
an output stream -- will _not_ write the ANSI codes to that file.

## Basic Usage

```elixir
defmodule Pretty.Cryptography do
  use Painter, color: :magenta
end
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `painter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:painter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/painter](https://hexdocs.pm/painter).

# TODO
 - [ ] add ability to globally change contrast/darken/lighten
 - [ ] theeeeeeeeeeeemes