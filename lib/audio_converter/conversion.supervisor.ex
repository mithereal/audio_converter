defmodule AudioConverter.Conversion.Supervisor do
  use DynamicSupervisor
  use GenServer
  require Logger
  @name :conversion_supervisor

  @moduledoc false

  def child_spec([args]) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  def start_child(args) do
    spec = {AudioConverter.Conversion.Server, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: @name)
  end

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: args
    )
  end

  def start(args) do
    AudioConverter.Conversion.Server.start_link(args)
  end
end
