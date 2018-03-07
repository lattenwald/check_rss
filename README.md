# CheckRss

You have a list of URLs and want to check, do they have RSS links embedded? Look no further.

## Installation

1. have Elixir installed.
2. clone repo
3. `mix escript.build`
4. `./check_rss.ex --help`

        Usage: `check_rss.ex --help`
               `check_rss.ex --url https://your.site
               `check_rss.ex [options] file_with_urls
         
        Available options:
         
          * --help  -h  -- Show help
          * --url   -u  -- Check single URL
          * --concurrency int  -c int  -- concurrently running sites checks
         
        Check URLs from file for advertised RSS feeds. File should contain one URL per line

Prints results to STDOUT; all separators are `<tab>`, not spaces

        <url> ok  <tab-separated list of found RSS links>
        <url> error <inspect of error>
