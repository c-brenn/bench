defmodule Bench.Timer do
  alias Bench.Logger

  def time(operation_type, num_operations, module, function) do
    Logger.log_header("Timing #{num_operations} #{operation_type} operations for: #{to_string(module)}")
    {time, _} = :timer.tc(function)
    time
  end
end
