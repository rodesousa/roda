defmodule Roda.Date do
  def beginning_of_week(), do: Date.beginning_of_week(Date.utc_today())

  def end_of_week(), do: Date.end_of_week(Date.utc_today())

  @doc """
  Returns a list of the last N complete weeks as {start_date, end_date} tuples.
  Excludes the current week.

  ## Examples

      iex> last_complete_weeks(3)
      [
        {~D[2025-10-21], ~D[2025-10-27]},
        {~D[2025-10-14], ~D[2025-10-20]},
        {~D[2025-10-07], ~D[2025-10-13]}
      ]
  """
  def last_complete_weeks(count) do
    today = Date.utc_today()
    current_week_start = Date.beginning_of_week(today)

    # Start from last week (current_week_start - 1 day)
    last_week_end = Date.add(current_week_start, -1)

    Enum.map(0..(count - 1), fn week_offset ->
      week_end = Date.add(last_week_end, -week_offset * 7)
      week_start = Date.beginning_of_week(week_end)
      {week_start, week_end}
    end)
  end

  @doc """
  Returns the ISO week number for a given date.
  """
  def week_number(%Date{} = date) do
    {_, week} = Timex.iso_week(date)
    week
  end

  @doc """
  iex> display_date(~N[2023-09-13 13:03:47])
  "13 September 2023"

  iex> display_date(~D[2024-01-11])
  "11 January 2024"

  iex> display_date(~D[2024-01-11])
  "11 January 2024"

  iex> display_date(~D[2024-01-11], [:short])
  "11/01/2024"
  """
  @spec display_date(%NaiveDateTime{} | %Date{}, list()) :: String.t()
  def display_date(date, options \\ []) do
    month =
      date
      |> Timex.format!("%B", :strftime)
      |> String.downcase()
      |> month()

    number_month =
      Timex.format!(date, "{M}")
      |> case do
        "1" -> "01"
        "2" -> "02"
        "3" -> "03"
        "4" -> "04"
        "5" -> "05"
        "6" -> "06"
        "7" -> "07"
        "8" -> "08"
        "9" -> "09"
        number -> number
      end

    day = Timex.format!(date, "%d", :strftime)
    year = Timex.format!(date, "%Y", :strftime)

    if :short in options do
      "#{day}/#{number_month}/#{year}"
    else
      "#{day} #{month} #{year}"
    end
  end

  use Gettext, backend: RodaWeb.Gettext

  @doc """
  Returns month with `gettext/1`
  TODO: NOT IN THE RIGHT PLACE !!!!!

  iex> month("january")
  gettext("January")
  """
  def month("january"), do: gettext("January")
  def month("february"), do: gettext("February")
  def month("march"), do: gettext("March")
  def month("april"), do: gettext("April")
  def month("may"), do: gettext("May")
  def month("june"), do: gettext("June")
  def month("july"), do: gettext("July")
  def month("august"), do: gettext("August")
  def month("september"), do: gettext("September")
  def month("october"), do: gettext("October")
  def month("november"), do: gettext("November")
  def month("december"), do: gettext("December")
  def month(_), do: gettext("Michel !")
end
