defmodule MagSked.Courts do
  @moduledoc """
  Read API for current tennis court availability.

  Placeholder for now: returns static sample data. A GenServer will poll
  the upstream booking site every minute and cache the latest snapshot
  (in its own state / ETS / :persistent_term); `snapshot/0` just reads
  that cache, so this function stays cheap and synchronous and the web
  layer never talks to the upstream site directly.
  """

  @type slot :: %{time: String.t(), open: boolean()}
  @type court :: %{name: String.t(), slots: [slot()]}
  @type snapshot :: %{fetched_at: DateTime.t(), courts: [court()]}

  @spec snapshot() :: snapshot()
  def snapshot do
    %{
      fetched_at: DateTime.utc_now(),
      courts: [
        %{name: "Court 1", slots: sample(~w(08:00 09:00 14:00))},
        %{name: "Court 2", slots: sample(~w(11:00))},
        %{name: "Court 3", slots: sample([])},
        %{name: "Court 4", slots: sample(~w(08:00 16:00 17:00 18:00))}
      ]
    }
  end

  defp sample(open_times) do
    for t <- ~w(08:00 09:00 10:00 11:00 14:00 16:00 17:00 18:00) do
      %{time: t, open: t in open_times}
    end
  end
end
