defmodule Bench.Datum do
  def new(operations) do
    %{
      operations: operations,
      stdlib: %{},
      vial: %{},
      phoenix: %{}
    }
  end

  def record(datum, accessors, value) do
    put_in(datum, accessors, value)
  end
end
