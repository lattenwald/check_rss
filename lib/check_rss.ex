defmodule CheckRss do
  require Logger
  import Supervisor.Spec

  @timeout 120_000

  def run(opts) do
    urls =
      case opts[:url] do
        nil -> read_urls(opts[:urls])
        url -> [url]
      end

    children = [
      supervisor(Task.Supervisor, [[name: CheckRss.TaskSupervisor, restart: :temporary]])
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Task.Supervisor.async_stream_nolink(
      CheckRss.TaskSupervisor,
      urls,
      fn url ->
        case check_url(url) do
          {:error, err} ->
            IO.puts("#{url}\terror\t#{inspect(err)}")

          {:ok, rss} ->
            try do
              IO.puts("#{url}\tok\t" <> Enum.join(rss, "\t"))
            catch
              type, err ->
                IO.puts("#{url}\twut #{inspect(type)} #{inspect(err)}\t#{inspect(rss)}")
            end
        end
      end,
      max_concurrency: opts[:concurrency] || 1,
      timeout: @timeout
    )
    |> Stream.run()
  end

  def read_urls(filename) do
    with {:ok, contents} <- File.read(filename) do
      String.split(contents, ~r{[\r\n]+}, trim: true)
    else
      err ->
        IO.puts(:stderr, "failed reading #{filename}: #{inspect(err)}")
        System.halt(1)
    end
  end

  def check_url(url) do
    with {:ok, %{body: body, status_code: 200}} <-
           HTTPoison.get(url, [], follow_redirect: true, max_redirect: 5) do
      rss = find_rss(url, body)
      {:ok, rss}
    else
      err -> {:error, err}
    end
  end

  def find_rss(_, nil), do: []

  def find_rss(url, body) do
    [proto, host] =
      Regex.run(
        ~r{^(.*)://([^/?]*)},
        url,
        capture: :all_but_first
      )

    Regex.scan(
      ~r{(<link\s[^>]*\brss\b[^>]*>|<a\s[^>]*>[^<]*rss[^<]*</a>|<a\s[^>]*rss[^>]*>)}i,
      body,
      capture: :all_but_first
    )
    |> List.flatten()
    |> Enum.map(fn candidate ->
      captures =
        Regex.named_captures(
          ~r{\bhref=(?<quo>['"])(?<url>.*?)\k<quo>}i,
          candidate
        )

      case captures["url"] do
        nil -> nil
        <<"//", _::binary>> -> proto <> captures["url"]
        <<"/", _::binary>> -> proto <> "://" <> host <> captures["url"]
        _ -> captures["url"]
      end
    end)
    |> Enum.uniq()
  end
end
