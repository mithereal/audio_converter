defmodule AudioConverter.MixProject do
  use Mix.Project

  def project do
    [
      app: :audio_converter,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_path: "./_build",
      config_path: "./config/config.exs",
      lockfile: "./mix.lock",
      deps_path: "./deps",
      name: "audio converter",
      source_url: "https://git.jdmellberg.com/jclark/audio_converter",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]


  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AudioConverter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, ">= 0.0.0", only: [:test, :dev]},
      {:mix_test_watch, ">= 0.0.0", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp aliases do
    [
      test: ["test"]
    ]
  end

  defp description() do
    "A server that watches your filesystem for changes and converts the new files (.wav) to a differrent format (.mp3)."
  end

  defp package() do
    [
      name: "audio_converter",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Jason Clark"],
      licenses: ["MIT"]
    ]
  end
end
