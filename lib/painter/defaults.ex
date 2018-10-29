defmodule Painter.Defaults do
  defmacro __using__(_) do
    caller = __CALLER__.module

    quote location: :keep do
      defmacro detail(message, opts \\ []) do
        import Printer, only: [parse: 1, line: 2, with_line_break: 2]
        import Painter, only: [pretty: 3]

        indent = 2
        footer = pretty(__CALLER__, parse(message), indent)

        quote do
          prefix = with_line_break(String.duplicate(" ", unquote(indent)), :before)
          suffix = unquote(footer) <> line(paint_color(), 80)
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

