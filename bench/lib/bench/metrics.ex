defmodule Bench.Metrics do
  def ops_per_sec(ops, usecs) do
    (ops * 1000000) / usecs |> round_float()
  end

  def time_per_op_usec(usecs, ops) do
    usecs / ops |> round_float()
  end

  def latency_per_op_usec(usecs, base_usecs) do
    usecs - base_usecs |> round_float()
  end

  def latency_per_op_percent(latency_usecs, base_usecs) do
    (latency_usecs * 100) / base_usecs |> round_float()
  end

  def round_float(float) do
    Float.round(float, 2)
  end

end
