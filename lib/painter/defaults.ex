defmodule Painter.Defaults do
  defmacro __using__(_) do
    caller = __CALLER__.module

    # quote location: :keep do
    quote location: :keep do
      defmacro detail(raw_message, opts \\ []) do
        indent = 2
        footer = Printer.pretty(__CALLER__, raw_message, 2 * indent)

        quote do
          footer_func = unquote(footer)
          value = unquote(raw_message)
          new_opts = Keyword.merge([suffix: footer_func], unquote(opts))
          message = Printer.do_indent(value, Painter.Opts.default_opts(true), unquote(indent))

          log(message, new_opts)
        end
      end

      def to_pretty(format_fun, message) do
        format_fun.(message)
      end

      def write(message, opts \\ []) do
        Painter.write(unquote(caller), message, opts)
      end
      
      def log(message, opts \\ []) do
        Painter.log(unquote(caller), message, opts)
      end
      
      def debug(message, opts \\ []) do
        Painter.debug(unquote(caller), message, opts)
      end
      
      def mark(message, opts \\ []) do
        Painter.mark(unquote(caller), message, opts)
      end
      
      def error(message, opts \\ []) do
        Painter.error(unquote(caller), message, opts)
      end
      
      def fail(cause \\ :unknown, opts \\ []) do
        Painter.fail(unquote(caller), cause, opts)
      end
    end
  end
end

