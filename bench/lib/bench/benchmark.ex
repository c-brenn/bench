defmodule Bench.Benchmark do
  alias Bench.{
    Datum,
    LogFile,
    Metrics
  }

  def run(type, generator, start, step, finish) do
    {:ok, log} = LogFile.new(type)

    indices = 0..((finish - start) |> div(step))

    results = Enum.map(indices, fn index ->
      operations = start + (index * step)

      {stdlib_status, stdlib_time} = generator.(StdLib, operations)
      :timer.sleep(500)
      {:ok, vial_time} = generator.(Vial, operations)
      :timer.sleep(500)
      {:ok, phoenix_time} = generator.(Phoenix, operations)

      vial_ops_per_sec = Metrics.ops_per_sec(operations, vial_time)
      vial_time_per_op_usec = Metrics.time_per_op_usec(vial_time, operations)

      phoenix_ops_per_sec = Metrics.ops_per_sec(operations, phoenix_time)
      phoenix_time_per_op_usec = Metrics.time_per_op_usec(phoenix_time, operations)


      datum =
        operations
        |> Datum.new()
        |> Datum.record([:vial, :time], vial_time)
        |> Datum.record([:phoenix, :time], phoenix_time)
        |> Datum.record([:vial, :ops_per_sec], vial_ops_per_sec)
        |> Datum.record([:vial, :time_per_op_usec], vial_time_per_op_usec)
        |> Datum.record([:phoenix, :ops_per_sec], phoenix_ops_per_sec)
        |> Datum.record([:phoenix, :time_per_op_usec], phoenix_time_per_op_usec)

      if stdlib_status == :ok do
        stdlib_ops_per_sec = Metrics.ops_per_sec(operations, stdlib_time)
        stdlib_time_per_op_usec = Metrics.time_per_op_usec(stdlib_time, operations)

        vial_latency_op_usec = Metrics.latency_per_op_usec(vial_time_per_op_usec, stdlib_time_per_op_usec)
        vial_latency_op_percent = Metrics.latency_per_op_percent(vial_latency_op_usec, stdlib_time_per_op_usec)

        phoenix_latency_op_usec = Metrics.latency_per_op_usec(phoenix_time_per_op_usec, stdlib_time_per_op_usec)
        phoenix_latency_op_percent = Metrics.latency_per_op_percent(phoenix_latency_op_usec, stdlib_time_per_op_usec)

        datum
        |> Datum.record([:stdlib, :time], stdlib_time)
        |> Datum.record([:stdlib, :ops_per_sec], stdlib_ops_per_sec)
        |> Datum.record([:stdlib, :time_per_op_usec], stdlib_time_per_op_usec)
        |> Datum.record([:vial, :latency_per_op_usec], vial_latency_op_usec)
        |> Datum.record([:vial, :latency_per_op_percent], vial_latency_op_percent)
        |> Datum.record([:phoenix, :latency_per_op_usec], phoenix_latency_op_usec)
        |> Datum.record([:phoenix, :latency_per_op_percent], phoenix_latency_op_percent)
      else
        datum
      end
    end)

    encoded = %{results: results} |> Poison.encode_to_iodata!(pretty: true)
    IO.puts(log, encoded)
    LogFile.close(log)
  end
end
