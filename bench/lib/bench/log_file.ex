defmodule Bench.LogFile do
  @log_dir "../logs"

  def new(operation) do
    file_name = timestamp() <> ".json"
    [@log_dir, operation, file_name]
    |> Path.join()
    |> File.open([:write, :exclusive])
  end

  def close(log), do: File.close(log)

  defp timestamp() do
    {{year, month, day}, {hour, min, sec}} = :calendar.universal_time()
    [year, month, day, hour, min, sec] |> Enum.join("_")
  end
end
