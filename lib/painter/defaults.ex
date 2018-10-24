defmodule Painter.Defaults do
  defmacro __using__(_) do
    caller = __CALLER__.module

    quote location: :keep do
      defmacro detail(message, opts \\ []) do
        import Printer, only: [parse: 1, across: 1]
        import Painter, only: [pretty: 3]
        import AnsiHelper, only: [do_ansi: 1]
        
        indent = 2
        footer = pretty(__CALLER__, parse(message), indent)
        quote do
          line = "\n" <> do_ansi(paint_color()) <> across(80) <> do_ansi(:reset) <> "\n"
          prefix = "\n" <> String.duplicate(" ", unquote(indent))
          suffix = unquote(footer) <> line
          new_opts = Keyword.merge([suffix: suffix, prefix: prefix], unquote(opts))
          log(unquote(message), new_opts)
        end
      end
      
      def write(message, path \\ :default_day, opts \\ [:append]),
        do: Painter.write(unquote(caller), message, path, opts)

      def log(message, opts \\ []), do: Painter.log(unquote(caller), message, opts)
      def debug(message, opts \\ []), do: Painter.debug(unquote(caller), message, opts)
      def mark(message, opts \\ []), do: Painter.mark(unquote(caller), message, opts)
      def error(message, opts \\ []), do: Painter.error(unquote(caller), message, opts)
    end
  end
end
