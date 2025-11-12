import Dotenvy

alias Roda.Repo
alias Roda.Accounts
alias Roda.Organizations
alias Roda.Organizations.{OrganizationMembership}

# This seed file is idempotent and can be run multiple times safely
# It creates the initial organization and admin user only if they don't exist

IO.puts("🌱 Running seeds...")

# Get configuration from environment variables
org_name = env!("INITIAL_ORG_NAME", :string, "Default Organization")
admin_email = env!("ADMIN_EMAIL", :string, "admin@example.com")
admin_password = env!("ADMIN_PASSWORD", :string!)

# Create or get organization
orga =
  case Repo.all(Organizations.Organization) do
    [] ->
      IO.puts("Creating initial organization: #{org_name}")
      Organizations.add_organization!(%{name: org_name})

    [first_orga | _] ->
      IO.puts("Organization already exists: #{first_orga.name}")
      first_orga
  end

# Create or get admin user
user =
  case Repo.get_by(Accounts.User, email: admin_email) do
    nil ->
      IO.puts("Creating admin user: #{admin_email}")

      {:ok, user} =
        Accounts.register_user_email_password(%{
          email: admin_email,
          password: admin_password
        })

      user

    existing_user ->
      IO.puts("Admin user already exists: #{admin_email}")
      existing_user
  end

# Create or get membership
membership =
  case Repo.get_by(OrganizationMembership,
         user_id: user.id,
         organization_id: orga.id
       ) do
    nil ->
      IO.puts("Creating admin membership")

      {:ok, membership} =
        %OrganizationMembership{}
        |> OrganizationMembership.changeset(%{
          organization_id: orga.id,
          user_id: user.id,
          role: "admin"
        })
        |> Repo.insert()

      membership

    existing_membership ->
      IO.puts("Membership already exists")
      existing_membership
  end

# Ensure user is super admin
case Roda.Accounts.PlatformAdmin.get(user.id) do
  nil ->
    IO.puts("Adding super admin privileges")
    Roda.Accounts.PlatformAdmin.add_super_admin(user.id)

  _ ->
    IO.puts("User is already super admin")
end

IO.puts("✅ Seeds completed successfully!")
