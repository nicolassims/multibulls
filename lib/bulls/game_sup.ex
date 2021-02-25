defmodule Bulls.GameSup do
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      arg,
      name: __MODULE__
    )
  end

  @impl true
  def init(_arg) do
    IO.puts("Starting superviesor")
    {:ok, _} = Registry.start_link(
      keys: :unique,
      name: Bulls.GameReg,
    )

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_child(spec) do
    IO.puts("Starting child")
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
