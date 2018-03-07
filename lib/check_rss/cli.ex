defmodule CheckRss.CLI do
  require Logger

  @moduledoc """
  Usage: `check_rss.ex --help`
         `check_rss.ex --url https://your.site
         `check_rss.ex [options] file_with_urls

  Available options:

    * --help  -h  -- Show help
    * --url   -u  -- Check single URL
    * --concurrency int  -c int  -- concurrently running sites checks

  Check URLs from file for advertised RSS feeds. File should contain one URL per line
  """

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    {parsed, rest, invalid} =
      OptionParser.parse(
        argv,
        switches: [help: :boolean, url: :string, concurrency: :integer],
        aliases: [h: :help, u: :url, c: :concurrency]
      )

    cond do
      length(invalid) > 0 ->
        {:invalid_opts, invalid}

      is_nil(parsed[:url]) and length(rest) != 1 ->
        :invalid_usage

      parsed[:help] ->
        :help

      true ->
        case rest do
          [urls] ->
            parsed
            |> Keyword.put_new(:urls, urls)
            |> Keyword.put_new(:concurrency, 10)

          _ ->
            parsed
        end
    end
  end

  def process(:help) do
    IO.puts(:stderr, @moduledoc)
    System.halt(0)
  end

  def process(:invalid_usage) do
    IO.puts(:stderr, @moduledoc)
    System.halt(1)
  end

  def process({:invalid_opts, invalid}) do
    invalid_str =
      invalid
      |> Enum.map(fn {key, _val} -> key end)
      |> Enum.join(", ")

    IO.puts(:stderr, "Unknown options: #{invalid_str}")

    System.halt(1)
  end

  def process(opts) do
    opts_str =
      opts
      |> Enum.map(fn {k, v} -> "--#{k} #{v}" end)
      |> Enum.join(" ")

    IO.puts(:stderr, "Running with options: #{opts_str}")

    CheckRss.run(opts)
  end
end
