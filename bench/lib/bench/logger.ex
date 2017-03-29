defmodule Bench.Logger do
  def log_header(header) do
    IO.puts ["\n", header, "\n", String.duplicate("=", String.length(header))]
  end

  def log_data(data, unit) do
    prefix_length =
      data
      |> Enum.map(fn {type, _} -> to_string(type) |> String.length() end)
      |> Enum.max()

    datum_length =
      data
      |> Enum.map(fn {_, x} -> to_string(x) |> String.length() end)
      |> Enum.max()

    for {type, raw_datum} <- data do
      prefix = to_string(type)
      datum = to_string(raw_datum)

      left_padding = (prefix_length + 2) - String.length(prefix)
      right_padding = (datum_length + 2) - String.length(datum)

      IO.puts [
        prefix,
        String.duplicate(" ", left_padding),
        "::",
        String.duplicate(" ", right_padding),
        datum,
        " #{unit}"
      ]
    end
  end
end
