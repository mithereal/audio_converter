defmodule AudioConverter.Cleanup.Task do
  use Task
  require Logger

  @moduledoc """
  The Process that runs the cleanup task for the mp3 converter.
  Verify if the  mp3 file is valid (using mp3val) and if valid optionally delete the source. 
  """

  @spec start_link(arg :: map()) :: nil

  @doc false
  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  @doc false
  def run(arg) do
    {status, percent} = :vice.status(arg.worker)

    {output, not_exists} = System.cmd("command ", ["-v mp3val"])

    case not_exists do
      1 ->
        Logger.warn("mp3val is not found")

      0 ->
        case status == 'running' do
          true ->
            run(arg)

          false ->
            {_, file_stats} = File.stat(arg.destination)
            filezise = file_stats.size

            case filezise > 0 do
              ## check if file passes validation
              true ->
                {output, status} = System.cmd("mp3val", [arg.destination + " -sm"])
                string_list = String.split(status, ":")
                validator = string_list[2]
                invalid? = String.contains?(validator, "No MPEG frames,")

                case invalid? do
                  true ->
                    nil

                  false ->
                    Logger.warn("Removing Source File: " <> arg.source)
                    File.rm(arg.source)
                end

              false ->
                nil
            end
        end
    end
  end
end
