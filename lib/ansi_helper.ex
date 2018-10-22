defmodule AnsiHelper do
  alias IO.ANSI

  @spec color?(maybe_color::any) :: boolean
  def color?(maybe_color) do
    maybe_color in colors()
  end
  
  @spec reverse(s::binary, nil | any)::s::binary
  def reverse(string, nil), do: string
  def reverse(string, _) do
    do_ansi(:reverse) <> string
  end

  @spec reset() :: binary
  def reset(), do: do_ansi(:reset)

  @spec do_ansi(color::atom) :: binary
  def do_ansi(nil), do: ""
  def do_ansi(color) do
    if ANSI.enabled? do
      apply(ANSI, color, [])
    else
        ""
    end
  end

  def colors do
    [
    :black,
    :black_background,
    :blink_off,
    :blink_rapid,
    :blink_slow,
    :blue,
    :blue_background,
    :bright,
    :clear,
    :clear_line,
    :color,
    :color,
    :color_background,
    :color_background,
    :conceal,
    :crossed_out,
    :cursor,
    :cursor_down,
    :cursor_down,
    :cursor_left,
    :cursor_left,
    :cursor_right,
    :cursor_right,
    :cursor_up,
    :cursor_up,
    :cyan,
    :cyan_background,
    :default_background,
    :default_color,
    :enabled?,
    :encircled,
    :faint,
    :font_1,
    :font_2,
    :font_3,
    :font_4,
    :font_5,
    :font_6,
    :font_7,
    :font_8,
    :font_9,
    :format,
    :format,
    :format_fragment,
    :format_fragment,
    :framed,
    :green,
    :green_background,
    :home,
    :inverse,
    :inverse_off,
    :italic,
    :light_black,
    :light_black_background,
    :light_blue,
    :light_blue_background,
    :light_cyan,
    :light_cyan_background,
    :light_green,
    :light_green_background,
    :light_magenta,
    :light_magenta_background,
    :light_red,
    :light_red_background,
    :light_white,
    :light_white_background,
    :light_yellow,
    :light_yellow_background,
    :magenta,
    :magenta_background,
    :no_underline,
    :normal,
    :not_framed_encircled,
    :not_italic,
    :not_overlined,
    :overlined,
    :primary_font,
    :red,
    :red_background,
    :reset,
    :reverse,
    :reverse_off,
    :underline,
    :white,
    :white_background,
    :yellow,
    :yellow_background
  ]
end
end