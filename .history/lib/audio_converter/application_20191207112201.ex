defmodule AudioConverter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    source_directory = Application.get_env(:audio_converter, :source_directory)

    config = [
      opts: source_directory,
      latency: 0,
      watch_root: true
    ]

    children = [
      # Starts a worker by calling: AudioConverter.Worker.start_link(arg)
      {AudioConverter.Watcher.Server, config}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AudioConverter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
