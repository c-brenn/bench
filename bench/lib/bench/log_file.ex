defmodule Bench.LogFile do
  @log_dir "../logs"

  def new(name) do
    file_name = add_timestamp(name) <> ".json"
    @log_dir
    |> Path.join(file_name)
    |> File.open([:write, :exclusive])
  end

  def close(log), do: File.close(log)

  defp add_timestamp(name) do
    {{year, month, day}, {hour, min, sec}} = :calendar.universal_time()
    [name, year, month, day, hour, min, sec] |> Enum.join("_")
  end
end
