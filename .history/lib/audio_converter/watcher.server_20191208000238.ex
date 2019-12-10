defmodule AudioConverter.Watcher.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info({:file_event, watcher_pid, {path, events}}, %{watcher_pid: watcher_pid} = state) do
    case events do
      _ -> nil
    end

    # YOUR OWN LOGIC FOR PATH AND EVENTS
    # get the new filename
    # start a genserver and wait for the file lock to be removedor start a timer, periodically check fo r file growtu say everty 30 sec 
    # Conversionn.Supervisor.start(path)
    # start the conversion
    # create the db entry if the table is there and/or db is connected
    # remove the old file
    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    # YOUR OWN LOGIC WHEN MONITOR STOP
    {:noreply, state}
  end
end
