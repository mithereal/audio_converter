# AudioConverter

** A genserver that watches your filesystem for changes and converts the new files (.wav) to a different format (.mp3). **

## Installation

The package can be installed
by adding `audio_converter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:audio_converter, git: "https://github.com/mithereal/audio_converter.git"}
  ]
end
```


## Host OS Dependencies

cmake, ffmpeg|libav, libopencv-dev, imagemagick, SoX, inotify

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

