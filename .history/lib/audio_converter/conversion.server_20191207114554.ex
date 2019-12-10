defmodule AudioConverter.Conversion.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {source,dest} = args
    vice:start()
    {async, worker} = vice:convert(source, dest)
    {:ok, args}
  end
end
