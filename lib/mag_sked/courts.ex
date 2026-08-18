defmodule MagSked.Courts do
  @moduledoc """
  Read API for current court availability.
  """

  use GenServer

  alias MagSked.Courts.Snapshot

  require Logger

  @type time :: String.t()
  @type span :: [time()]
  @type spans :: [span()]
  @type day :: String.t()
  @type avail :: %{day() => spans()}
  @type courtn :: 1..3
  @type court_avail :: %{courtn() => avail()}
  @type lookup_map :: %{day() => [{time(), %{courtn() => true}}]}

  # called by the supervisor
  def start_link(arg) do
    # start a GenServer process using the callback in this module
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg \\ nil) do
    :ets.new(:cache, [:named_table, :set, :public, read_concurrency: true])
    state_from_db = Snapshot.get_latest()

    for court_num <- [1, 2, 3], avail_for_court = state_from_db[court_num] do
      :ets.insert(:cache, {court_num, avail_for_court})
    end

    send(self(), :fetch_courts)

    {:ok, :starting}
  end

  def current do
    for i <- [1, 2, 3], [{^i, avail}] = :ets.lookup(:cache, i), into: %{} do
      {i, avail}
    end
  end

  @spec avail_lookup_map(court_avail()) :: lookup_map()
  def avail_lookup_map(court_avail) do
    nested_map =
      for {court, avail_by_date} <- court_avail,
          {date, spans} <- avail_by_date,
          span <- spans,
          time <- span,
          reduce: %{} do
        acc -> put_in(acc, [Access.key(date, %{}), Access.key(time, %{}), court], true)
      end

    # convert the maps that have times as keys to {time, avail} lists so they're ordered
    for {date, times_map} <- nested_map, into: %{} do
      sorted_times = Enum.sort_by(times_map, fn {time, _avail} -> time end)

      grouped_reversed_times =
        for {time, _avail} = curr <- sorted_times, prev_time = minus_30_min(time), reduce: [] do
          # keep adding to the previous group
          [[{^prev_time, _} | _] = current_group | earlier_groups] ->
            [[curr | current_group] | earlier_groups]

          # start a new group
          list ->
            [[curr] | list]
        end

      # have to reverse the nested lists and the outer one
      grouped_times = grouped_reversed_times |> Enum.map(&Enum.reverse(&1)) |> Enum.reverse()

      {date, grouped_times}
    end
  end

  def possible_times do
    for h <- 9..21, min <- ["00", "30"] do
      "#{String.pad_leading(Integer.to_string(h), 2, "0")}:#{min}"
    end
  end

  # 1-indexed starting on monday
  @day_names_by_dow %{
    1 => "Mon",
    2 => "Tue",
    3 => "Wed",
    4 => "Thu",
    5 => "Fri",
    6 => "Sat",
    7 => "Sun"
  }

  def snapshot do
    lookup_map = avail_lookup_map(current())

    today = Date.utc_today()

    for n <- 0..7 do
      date = Date.add(today, n)
      date_str = Date.to_string(date)
      dow = Date.day_of_week(date)

      %{date: date, dow_text: @day_names_by_dow[dow], avail: lookup_map[date_str]}
    end
  end

  @impl true
  def handle_info(:fetch_courts, state) do
    for court_num <- [1, 2, 3] do
      case fetch_availability(court_num) do
        {:error, _} -> :error
        {:ok, avail} -> :ets.insert(:cache, {court_num, avail})
      end
    end

    # populate the cache
    if state == :starting, do: send(self(), :write_ets_to_db)

    Process.send_after(self(), :fetch_courts, to_timeout(minute: 1))

    {:noreply, nil}
  end

  @impl true
  def handle_info(:write_ets_to_db, state) do
    for court_num <- [1, 2, 3],
        [{^court_num, avail}] = :ets.lookup(:cache, court_num) do
      Snapshot.save(court_num, avail)
    end

    Process.send_after(self(), :write_ets_to_db, to_timeout(minute: 5))

    {:noreply, state}
  end

  @padel_court_resources %{1 => 127, 2 => 129, 3 => 130}
  def fetch_availability(court) do
    Logger.info("fetching court #{court}")

    case Req.get(
           "https://simplifica.madeira.gov.pt/api/infoProcess/32/resources/#{@padel_court_resources[court]}/configuration"
         ) do
      {:ok, %{body: body}} ->
        avail_iso_dts =
          for %{"reservations" => 0, "begin" => %{"date" => iso_dt}} <- body["data"]["intervals"] do
            iso_dt
          end

        {:ok, avail_blocks_by_date(avail_iso_dts)}

      {:error, reason} ->
        Logger.error("Failed to fetch court #{court}: #{inspect(reason)}")
        {:error, :fetch_error}
    end
  end

  @doc """
  Accept a flat, unsorted list of iso datetime strings.
  Return a map of date strings to nested lists of time strings.
  Each list in the nested list is a contiguous list of available times (each time slot is 30 minutes).
  The list of lists is chronologically ordered.

  Because one must book at least a contiguous hour, blocks of a single half-hour slot are removed from
  the results.

    iex> MagSked.Courts.avail_blocks_by_date([
    ...>   "2026-08-08 14:00:00", "2026-08-08 14:30:00", "2026-08-08 15:00:00",
    ...>   "2026-08-08 20:00:00", "2026-08-08 20:30:00",
    ...>   "2026-08-07 13:30:00", "2026-08-07 14:00:00",
    ...>   "2026-08-07 18:30:00"
    ...> ]) # <- 18:30 will be filtered out
    %{"2026-08-07" => [["13:30", "14:00"]], "2026-08-08" => [["14:00", "14:30", "15:00"], ["20:00", "20:30"]]}
  """
  def avail_blocks_by_date(avail_iso_dts) do
    avail_times_by_date =
      avail_iso_dts
      |> Enum.sort()
      |> Enum.map(fn dt ->
        [date, time | _] = Regex.split(~r/[\s\.]/, dt)
        %{date: date, time: String.replace_suffix(time, ":00", "")}
      end)
      |> Enum.group_by(& &1.date, & &1.time)
      |> Map.new()

    acc = Map.new(avail_times_by_date, fn {date, _} -> {date, []} end)

    avail_time_groups_by_date_reversed =
      for {date, times} <- avail_times_by_date,
          time <- times,
          prev = minus_30_min(time),
          reduce: acc do
        %{^date => [[^prev | _] = group | rest]} = acc ->
          %{acc | date => [[time | group] | rest]}

        %{^date => groups} = acc ->
          %{acc | date => [[time] | groups]}
      end

    Map.new(avail_time_groups_by_date_reversed, fn {date, time_groups} ->
      reversed_y_filtered =
        time_groups
        |> Enum.reverse()
        |> Enum.map(&Enum.reverse/1)
        |> Enum.reject(&match?([_just_one], &1))

      {date, reversed_y_filtered}
    end)
  end

  def minus_30_min(time) do
    case String.split(time, ":") do
      [h, "00"] -> "#{String.pad_leading(Integer.to_string(String.to_integer(h) - 1), 2, "0")}:30"
      [h, "30"] -> "#{h}:00"
    end
  end
end
