defmodule Utilities.Hooks do
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
      result =
        File.open(filename, [:write], fn file ->
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