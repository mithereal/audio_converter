defmodule AudioConverter.Watcher.Server do
  use GenServer
  require Logger

  @moduledoc false

  alias AudioConverter.Watcher.Server, as: WATCHER

  @name :watcher

  defstruct start_time: :erlang.system_time(),
            total_files: 0,
            queued_files: 0,
            converted_files: 0,
            watcher_pid: nil,
            paths: [],
            status: :disabled

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def show() do
    GenServer.call(@name, :show)
  end

  def start() do
    GenServer.call(@name, {:status, :enabled})
  end

  def stop() do
    GenServer.call(@name, {:status, :disabled})
  end

  def init(args) do
    [dirs, _, _, is_enabled] = args

    {_dirs, dirs} = dirs

    IO.inspect(is_enabled)

    source_dir =
      case dirs.source_directory == "" || dirs.source_directory == nil do
        true -> File.cwd!()
        false -> dirs.source_directory
      end

    destination_dir =
      case dirs.destination_directory == "" || dirs.destination_directory == nil do
        true -> File.cwd!()
        false -> dirs.destination_directory
      end

    remove_source = Application.get_env(:audio_conversion, :remove_source)

    state =
      case(is_enabled) do
        _ ->
          %__MODULE__{watcher_pid: nil, paths: dirs, status: :disabled}

        true ->
          {:ok, watcher_pid} = FileSystem.start_link(dirs: [source_dir])
          FileSystem.subscribe(watcher_pid)
          Logger.info("Starting Directory Watcher")
          Logger.info("The Audio Source Directory is: #{source_dir}")
          Logger.info("The Converted Audio Output Directory is: #{destination_dir}")
          Logger.info("Remove Audio Source Files: #{remove_source}")
          %__MODULE__{watcher_pid: watcher_pid, paths: dirs, status: :enabled}

        {:enabled, true} ->
          {:ok, watcher_pid} = FileSystem.start_link(dirs: [source_dir])
          FileSystem.subscribe(watcher_pid)
          Logger.info("Starting Directory Watcher")
          Logger.info("The Audio Source Directory is: #{source_dir}")
          Logger.info("The Converted Audio Output Directory is: #{destination_dir}")
          Logger.info("Remove Audio Source Files: #{remove_source}")
          %__MODULE__{watcher_pid: watcher_pid, paths: dirs, status: :enabled}
      end

    {:ok, state}
  end

  def handle_call(:file_converted, _, state) do
    {:reply, state, state}
  end

  def handle_call(:show, _, state) do
    {:reply, state, state}
  end

  def handle_call({:status, value}, _, state) do
    state =
      case(value) do
        :enabled ->
          alive? =
            case(state.watcher_pid) do
              nil -> false
              _ -> Process.alive?(state.watcher_pid)
            end

          {_, watcher_pid} =
            case(alive?) do
              true ->
                Logger.info("Directory Watcher Already Running")
                {:ok, state.watcher_pid}

              false ->
                {status, pid} = FileSystem.start_link(dirs: [state.paths.source_directory])

                FileSystem.subscribe(pid)
                Logger.info("Started Directory Watcher")
                {status, pid}
            end

          %{state | status: value}

        _ ->
          # Process.send({:file_event, state.watcher_pid, :stop})

          %{state | status: :disabled}
      end

    {:reply, state, state}
  end

  def handle_info(
        {:file_event, watcher_pid, {path, events}},
        %{
          start_time: start_time,
          total_files: total_files,
          queued_files: queued_files,
          converted_files: converted_files,
          watcher_pid: watcher_pid,
          paths: paths,
          status: status
        } = state
      ) do
    state =
      case events do
        [:created] ->
          extension = Path.extname(path)

          case extension == ".wav" do
            false ->
              state

            true ->
              ## update the start time to reflect actual time of the first file created event
              system_time =
                case state.total_files == 0 do
                  true ->
                    stats = File.stat(path)
                    {:ok, stats} = stats

                    {_, created} = NaiveDateTime.from_erl(stats.ctime)

                    t = NaiveDateTime.to_string(created)
                    GenServer.cast(AudioConverter.Metrics.Server, {:date_started, t})
                    t

                  false ->
                    state.start_time
                end

              remove_source = Application.get_env(:audio_conversion, :remove_source)

              args = %{
                source: path,
                destination: paths.destination_directory,
                remove_source: remove_source
              }

              AudioConverter.Conversion.Supervisor.start_child([args])

              state = %{state | start_time: system_time}

              state = %{state | total_files: state.total_files + 1}

              %{state | queued_files: state.queued_files + 1}
          end

        _ ->
          state
      end

    {:noreply, state}
  end

  def handle_info(
        {:file_event, watcher_pid, :stop},
        %{
          start_time: start_time,
          total_files: total_files,
          queued_files: queued_files,
          converted_files: converted_files,
          watcher_pid: watcher_pid,
          paths: paths,
          status: status
        } = state
      ) do
    GenServer.call(watcher_pid, {:stop, "graceful stop", state})
    Logger.info("Stopped Directory Watcher")
    state = %{state | status: :disabled}
    {:noreply, state}
  end
end
