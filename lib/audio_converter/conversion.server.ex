defmodule AudioConverter.Conversion.Server do
  use GenServer
  require Logger

  @moduledoc """
  The Process responsible for managing a single audio file conversion.
  """

  @lock_interval_seconds 10000

  defstruct(
    filesize: [],
    source: nil,
    destination: nil,
    remove_source: false
  )

  @doc false
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args},
      restart: :temporary,
      shutdown: 5000,
      type: :worker
    }
  end

  @doc false
  def start_link(args) do
    # :jobs.add_queue("audio conversions", [:passive])
    GenServer.start_link(__MODULE__, args)
  end

  @doc false
  def init([args]) do
    init(args)
  end

  @doc false
  def init(args) do
    %{destination: destination, source: source, remove_source: remove_source} = args

    {_, file_stats} = File.stat(source)

    filezise = file_stats.size

    source_file = Path.basename(source)

    source_file_parts = String.split(source_file, ".")

    dest_filename = destination <> List.first(source_file_parts) <> ".mp3"

    args = %{
      source: source,
      destination: dest_filename,
      filesize: [filezise],
      remove_source: remove_source
    }

    Logger.info("Queueing Conversion for File: " <> source)

    GenServer.cast(AudioConverter.Metrics.Server, :queue_mp3_conversion)

    :vice.start()

    Process.send_after(self(), :file_locked?, @lock_interval_seconds)

    {:ok, args}
  end

  @doc false
  def handle_info(:file_locked?, state) do
    {_, file_stats} = File.stat(state.source)

    filezise = file_stats.size

    filesizes =
      case Enum.count(state.filesize) > 3 do
        true ->
          last_filesizes = Enum.take(state.filesize, -4)
          list_sum = Enum.sum(last_filesizes)
          expected_sum = filezise * 4

          case list_sum == expected_sum do
            true -> Process.send_after(self(), :ready_to_encode, @lock_interval_seconds)
            false -> Process.send_after(self(), :file_locked?, @lock_interval_seconds)
          end

          state.filesize ++ [filezise]

        false ->
          Process.send_after(self(), :file_locked?, @lock_interval_seconds)
          state.filesize ++ [filezise]
      end

    new_state = %{state | filesize: filesizes}
    {:noreply, new_state}
  end

  @doc false
  def handle_info(:ready_to_encode, state) do
    # process input and compute result
    {async, worker} = :vice.convert(state.source, state.destination)

    case async do
      :error ->
        {error, _} = worker
        Logger.error(error)

      _ ->
        basename = Path.basename(state.source)
        destname = Path.basename(state.destination)
        Logger.info("Starting .mp3 Conversion for File: #{basename}")
        GenServer.cast(AudioConverter.Metrics.Server, {:last_file, destname})
      # :jobs.add_queue("audio conversions counter", [
      #   {:standard_counter, 3},
      #   {:producer, dequeue()}
      # ])
    end

    delete_source_file? = state.remove_source

    case delete_source_file? do
      true ->
        args = %{worker: worker, source: state.source, destination: state.destination}
        AudioConverter.Cleanup.Task.start_link(args)

      false ->
        nil

      _ ->
        nil
    end

    shutdown(worker, state)

    # {:noreply, state}
  end

  @doc false
  def dequeue() do
    :jobs.dequeue("audio conversions", 3)
  end

  @doc false
  def shutdown(worker, state) do
    {status, _} = :vice.status(worker)

    case status == 'running' do
      true ->
        shutdown(worker, state)

      false ->
        GenServer.cast(AudioConverter.Metrics.Server, :mp3_file_converted)
        {:stop, {:shutdown, "Task Completed"}, state}
    end
  end
end