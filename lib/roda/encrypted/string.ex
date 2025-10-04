defmodule Roda.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: Roda.Vault
end
