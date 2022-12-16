defmodule AudioConverter.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application
    use Supervisor

    def start(_type, _args) do
      settings = Core.Settings.Server.find_by_group("audio_conversion")

      source_setting = Core.Settings.Server.find_by_key("SOURCE_DIRECTORY", settings)

      destination_setting = Core.Settings.Server.find_by_key("DESTINATION_DIRECTORY", settings)

      enabled_setting = Core.Settings.Server.find_by_key("ENABLED", settings)

      enabled_setting =
        case(enabled_setting) do
          "true" -> true
          _ -> false
        end

      source_directory =
        case source_setting do
          nil -> Application.get_env(:audio_conversion, :source_directory)
          x -> source_setting.value
        end

      destination_directory =
        case destination_setting do
          nil -> Application.get_env(:audio_conversion, :destination_directory)
          x -> destination_setting.value
        end

      config = [
        dirs: %{source_directory: source_directory, destination_directory: destination_directory},
        latency: 0,
        watch_root: true,
        enabled: false
      ]

      children = [
        # Starts the filesystem watcher: AudioConverter.Watcher.Server.start_link(arg)
        {AudioConverter.Watcher.Server, config},
        {AudioConverter.Metrics.Server, []},
        {DynamicSupervisor, strategy: :one_for_one, name: AudioConverter.Conversion.Supervisor}
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: AudioConverter.Supervisor]
      Supervisor.start_link(children, opts)
    end

    def stop() do
      AudioConverter.Watcher.Server.stop()
    end

    def reload() do
      AudioConverter.Watcher.Server.start()
    end
  end
