defmodule KileedClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :kileed_client,
      version: "0.0.1",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/alisinabh/kileed_client_elixir",
      name: "Kileed Client",
      description: description(),
      build_embedded: Mix.env() == :prod,
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.2"},
      {:poison, "~> 4.0"},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Kileed authentication service client for elixir."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "kileed_client",
      # These are the default files included in the package
      files: ~w(lib mix.exs README* LICENSE),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/alisinabh/kileed_client_elixir"},
      maintainers: ["Alisina Bahadori"]
    ]
  end
end
