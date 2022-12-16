defmodule AudioConverter.Metrics.Server do
  use GenServer

  require Logger
  @name __MODULE__

  @moduledoc false

  defstruct audio_conversion: %{
              date_started: nil,
              last_file: nil,
              converted_files: 0,
              queued_files: 0,
              total_files: 0
            }

  def start_link(init = []) do
    GenServer.start_link(__MODULE__, init, name: @name)
  end

  def init([]) do
    initial_state = %__MODULE__{}

    {:ok, initial_state}
  end

  def load(data) do
    GenServer.cast(__MODULE__, {"load", data})
  end

  def show() do
    GenServer.call(__MODULE__, "show")
  end

  def handle_cast(:mp3_file_converted, state) do
    audio_conversion = state.audio_conversion
    converted_files = audio_conversion.converted_files
    queued_files = audio_conversion.total_files - audio_conversion.converted_files - 1

    audio_conversion = %{audio_conversion | converted_files: converted_files + 1}
    audio_conversion = %{audio_conversion | queued_files: queued_files}
    audio_conversion = %{audio_conversion | last_file: nil}

    state = %{state | audio_conversion: audio_conversion}

    result = {:ok, audio_conversion}
    Api.Audio.File.Conversions.metrics(result)

    {:noreply, state}
  end

  def handle_cast({:date_started, data}, state) do
    audio_conversion = state.audio_conversion

    audio_conversion = %{audio_conversion | date_started: data}
    state = %{state | audio_conversion: audio_conversion}

    {:noreply, state}
  end

  def handle_cast(:queue_mp3_conversion, state) do
    audio_conversion = state.audio_conversion
    queued_files = audio_conversion.queued_files
    total_files = audio_conversion.total_files

    audio_conversion = %{audio_conversion | queued_files: queued_files + 1}
    audio_conversion = %{audio_conversion | total_files: total_files + 1}
    state = %{state | audio_conversion: audio_conversion}

    result = {:ok, audio_conversion}
    Api.Audio.File.Conversions.metrics(result)

    {:noreply, state}
  end

  def handle_cast({:last_file, filename}, state) do
    audio_conversion = state.audio_conversion
    queued_files = audio_conversion.queued_files

    audio_conversion = %{audio_conversion | queued_files: queued_files + 1}
    audio_conversion = %{audio_conversion | last_file: filename}
    state = %{state | audio_conversion: audio_conversion}

    result = {:ok, audio_conversion}
    Api.Audio.File.Conversions.metrics(result)

    {:noreply, state}
  end

  ## server funs

  def handle_cast({"load", data}, state) do
    updated_state = %__MODULE__{state | audio_conversion: data}
    {:noreply, updated_state}
  end

  def handle_call("show", _, state) do
    {:reply, state, state}
  end
end
