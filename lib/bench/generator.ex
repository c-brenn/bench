defmodule Bench.Generator do
  alias MapSet, as: Set

  def write_function(type, operations, set) do
    fn ->
      Enum.reduce(1..operations, set, add_function(type))
    end
  end

  def new_set(Vial),    do: Vial.Set.new(:vial)
  def new_set(Phoenix), do: Phoenix.Tracker.State.new(:phoenix)
  def new_set(StdLib),  do: Set.new()

  defp add_function(Vial) do
    fn i, set ->
      Vial.Set.add(set, i, self(), %{})
    end
  end
  defp add_function(Phoenix) do
    fn i, set ->
      Phoenix.Tracker.State.join(set, self(), i, i, %{})
    end
  end
  defp add_function(StdLib) do
    fn i, set ->
      Set.put(set, {self(), i})
    end
  end
end
