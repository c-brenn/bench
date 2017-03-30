defmodule Bench.Generator do
  def write_function(module, operations, set) do
    fn ->
      Enum.reduce(1..operations, set, add_function(module))
    end
  end

  def read_function(module, operations, keys, set, size) do
    fn ->
      Stream.cycle(1..keys)
      |> Stream.take(operations)
      |> Enum.each(fn key ->
        if get_function(module).(key, set) |> Enum.count() != size do
          throw "key: #{key} got #{get_function(module).(key, set) |> Enum.count() }"
        end
      end)
    end
  end

  def new_set(Vial),    do: Vial.Set.new(:vial)
  def new_set(Phoenix), do: Phoenix.Tracker.State.new(:phoenix)
  def new_set(StdLib),  do: :ets.new(:foo, [:bag, :protected])

  def cleanup(StdLib, set), do: :ets.delete(set)
  def cleanup(Vial, set), do: :ets.delete(set.table)
  def cleanup(Phoenix, set) do
    :ets.delete(set.pids)
    :ets.delete(set.values)
  end

  defp add_function(Vial) do
    fn key, set ->
      Vial.Set.add(set, key, make_ref(), %{})
    end
  end
  defp add_function(Phoenix) do
    fn key, set ->
      Phoenix.Tracker.State.join(set, make_ref(), key, key, %{})
    end
  end
  defp add_function(StdLib) do
    fn key, set ->
      :ets.insert(set, {key, make_ref()})
      set
    end
  end

  defp get_function(Vial) do
    fn key, set -> Vial.Set.list(set, key)
    end
  end
  defp get_function(Phoenix) do
    fn key, set ->
      Phoenix.Tracker.State.get_by_topic(set, key)
    end
  end
  defp get_function(StdLib) do
    fn key, set ->
      :ets.lookup(set, key)
    end
  end
end
