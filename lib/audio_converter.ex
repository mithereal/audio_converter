defmodule AudioConverter do
  @moduledoc """
  Documentation for AudioConverter.
  """

  def convert_dir(source, destination, remove_source \\ false) do
    Logger.info("Converting Directory: #{source}")

    files = Core.FlatFiles.list_all(source)

    Logger.info("Files Found: #{Enum.count(files)}")

    Enum.map(files, fn file ->
      destination = destination <> "/"
      args = %{source: file, destination: destination, remove_source: remove_source}

      AudioConverter.Conversion.Supervisor.start_child([args])
    end)

    {:ok, "Processing..."}
  end

  @doc false
  def convert(source, destination) do
    :vice.start()
    {async, worker} = :vice.convert(source, destination)

    case async do
      :error ->
        {error, _} = worker
        Logger.error(error)

      _ ->
        basename = Path.basename(source)
        Logger.info("Starting  Conversion: #{basename}")
    end

    wait_till_finished(worker)
  end

  @doc false
  def wait_till_finished(worker) do
    vice = :vice.status(worker)

    case vice do
      :done ->
        worker

      {status, _} ->
        case status do
          :running ->
            wait_till_finished(worker)

          _ ->
            worker
        end
    end
  end

  @doc """
  Version

  ## Examples

      iex> AudioConverter.version()

  """
  @version Mix.Project.config()[:version]
  def version, do: @version
end
