defmodule Roda.Telemetry.AuditHandler do
  @moduledoc """
  Handles audit events from telemetry for security logging.

  Logs all sensitive operations like group creation, member management,
  access denials, etc.
  """

  require Logger

  @doc """
  Handles audit events from telemetry.

  ## Example

      :telemetry.execute(
        [:roda, :organizations, :group, :created],
        %{count: 1},
        %{user_id: 1, organization_id: 5, group_name: "Marketing"}
      )
  """
  def handle_event(event_name, measurements, metadata, _config) do
    action = format_event_name(event_name)
    timestamp = DateTime.utc_now()

    # Log the audit event
    Logger.info("Audit event",
      event: action,
      user_id: metadata[:user_id],
      organization_id: metadata[:organization_id],
      project_id: metadata[:project_id],
      resource_type: metadata[:resource_type],
      resource_id: metadata[:resource_id],
      resource_name: metadata[:resource_name],
      additional_data: filter_metadata(metadata),
      measurements: measurements,
      timestamp: timestamp
    )
  end

  defp format_event_name(event_list) when is_list(event_list) do
    event_list
    |> Enum.join(".")
  end

  defp filter_metadata(metadata) do
    # Remove standard keys to keep only additional data
    metadata
    |> Map.drop([
      :user_id,
      :organization_id,
      :project_id,
      :resource_type,
      :resource_id,
      :resource_name
    ])
  end
end
