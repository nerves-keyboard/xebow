defmodule Xebow.MixProject do
  use Mix.Project

  @app :xebow
  @version "0.1.0"
  @all_targets [:keybow]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.10",
      archives: [nerves_bootstrap: "~> 1.8"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: aliases(),
      deps: deps(),
      docs: [extras: ["README.md"]],
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host, dialyzer: :keybow],
      dialyzer: [
        ignore_warnings: "dialyzer.ignore.exs",
        list_unused_filters: true,
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "_build/#{Mix.target()}_#{Mix.env()}/plt/dialyxir.plt"}
      ]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Xebow.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp aliases do
    [
      dialyzer: "do cmd mkdir -p _build/#{Mix.target()}_#{Mix.env()}/plt, dialyzer",
      "docs.show": "do docs, cmd xdg-open doc/index.html",
      loadconfig: [&bootstrap/1]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.6.1", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},
      # {:chameleon, "~> 2.2"},
      # Open upstream PR:
      # https://github.com/supersimple/chameleon/pull/18
      {:chameleon, github: "amclain/chameleon", ref: "update-spec-for-new"},
      {:afk, "~> 0.3"},
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21.3", only: :dev, runtime: false},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.11", targets: @all_targets, override: true},
      {:nerves_pack, "~> 0.3", targets: @all_targets},
      {:vintage_net_wizard, "~> 0.2", target: @all_targets},
      {:circuits_gpio, "~> 0.4", targets: @all_targets},
      {:circuits_spi, "~> 0.1", targets: @all_targets},
      {:usb_gadget, github: "nerves-project/usb_gadget", ref: "master", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_keybow,
       github: "ElixirSeattle/nerves_system_keybow",
       ref: "v1.11.1+keybow.1",
       runtime: false,
       targets: :keybow}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
