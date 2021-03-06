defmodule Coherence do
  @moduledoc """
  Coherence is a full featured, configurable authentication and user
  management system for Phoenix, providing a number of optional features
  configured with a installation mix task:

  * Database Authenticatable: handles hashing and storing an encrypted password in the database.
  * Invitable: sends invites to new users with a sign-up link, allowing the user to create their account with their own password.
  * Registerable: allows anonymous users to register a users email address and password.
  * Confirmable: new accounts require clicking a link in a confirmation email.
  * Recoverable: provides a link to generate a password reset link with token expiry.
  * Trackable: saves login statics like login counts, timestamps, and IP address for each user.
  * Lockable: locks an account when a specified number of failed sign-in attempts has been exceeded.
  * Unlockable With Token: provides a link to send yourself an unlock email.
  * Rememberable: provides persistent login with 'Remember me?' check box on login page.

  See the [README](readme.html) file for an overview, installation, and
  setup instructions.

  ### Authenticatable

  Handles hashing and storing an encrypted password in the database.

  Provides `/sessions/new` and `/sessions/delete` routes for logging in and out with
  the appropriate templates and view.

  The following columns are added the `<timestamp>_add_coherence_to_user.exs` migration:

  * :password_hash, :string - the encrypted password

    * This name can be changed with the `password_hash_field` config item. Changing this requires recompiling Coherence.


  ### Invitable

  Handles sending invites to new users with a sign-up link, allowing the user to create their account with their own password.

  Provides `/invitations/new` and `invitations/edit` routes for creating a new invitation and creating a new account from the invite email.

  These routes can be configured to require login by using the `coherence_routes :private` macro in your router.exs file.

  Invitation token timeout will be added in the future.

  The following table is created by the generated `<timestamp>_create_coherence_invitable.exs` migration:

      create table(:invitations) do
        add :name, :string
        add :email, :string
        add :token, :string
      end

  ### Registerable

  Allows anonymous users to register a users email address and password.

  Provides `/registrations/new` and `/registrations/create` routes for creating a new registration.

  Adds a `Register New Account` to the log-in page.

  It is recommended that the :confirmable option is used with :registerable to
  ensure a valid email address is captured.

  ### Confirmable

  Requires a new account be conformed. During registration, a conformation token is generated and sent to the registering email. This link must be clicked before the user can sign-in.

  Provides `edit` action for the `/confirmations` route.

  The confirmation token expiry default of 5 days can be changed with the `:confirmation_token_expire_days` config entry.

  ### Recoverable

  Allows users to reset their password using an expiring token send by email.

  Provides `new`, `create`, `edit`, `update` actions for the `/passwords` route.

  Adds a "Forgot your password?" link to the log-in form. When clicked, the user provides their email address and if found, sends a reset password instructions email with a reset link.

  The expiry timeout can be changed with the `:reset_token_expire_days` config entry.

  ### Trackable

  Saves login statics like login counts, timestamps, and IP address for each user.

  Adds the following database field to your User model with the generated migration:

      add :sign_in_count, :integer, default: 0  # how many times the user has logged in
      add :current_sign_in_at, :datetime        # the current login timestamp
      add :last_sign_in_at, :datetime           # the timestamp of the previous login
      add :current_sign_in_ip, :string          # the current login IP adddress
      add :last_sign_in_ip, :string             # the IP address of the previous login

  ### Lockable

  Locks an account when a specified number of failed sign-in attempts has been exceeded.

  The following defaults can be changed with the following config entries:

  * `:unlock_timeout_minutes`
  * `:max_failed_login_attempts`

  Adds the following database field to your User model with the generated migration:

      add :failed_attempts, :integer, default: 0
      add :unlock_token, :string
      add :locked_at, :datetime

  ### Unlockable with Token

  Provides a link to send yourself an unlock email. When the user clicks the link, the user is presented a form to enter their email address and password. If the token has not expired and the email and password are valid, a unlock email is sent to the user's email address with an expiring token.

  The default expiry time can be changed with the `:unlock_token_expire_minutes` config entry.

  ### Remember Me

  The `rememberable` option provides persistent login when the 'Remember Me?' box is checked during login.

  With this feature, you will automatically be logged in from the same browser when your current login session dies using a configurable expiring persistent cookie.

  For security, both a token and series number stored in the cookie on initial login. Each new creates a new token, but preserves the series number, providing protection against fraud. As well, both the token and series numbers are hashed before saving them to the database, providing protection if the database is compromised.

  The following defaults can be changed with the following config entries:

  * :rememberable_cookie_expire_hours (2*24)
  * :login_cookie                     ("coherence_login")

  The following table is created by the generated `<timestamp>_create_coherence_rememberable.exs` migration:

      create table(:rememberables) do
        add :series_hash, :string
        add :token_hash, :string
        add :token_created_at, :datetime
        add :user_id, references(:users, on_delete: :delete_all)

        timestamps
      end
      create index(:rememberables, [:user_id])
      create index(:rememberables, [:series_hash])
      create index(:rememberables, [:token_hash])
      create unique_index(:rememberables, [:user_id, :series_hash, :token_hash])

  The `--rememberable` install option is not provided in any of the installer group options. You must provide the `--rememberable` option to install the migration and its support.

  ## Mix Tasks

  ### Installer

  The following examples illustrate various configuration scenarios for the install mix task:

      # Install with only the `authenticatable` option
      $ mix coherence.install

      # Install all the options except `confirmable` and `invitable`
      $ mix coherence.install --full

      # Install all the options except `invitable`
      $ mix coherence.install --full-confirmable

      # Install all the options except `confirmable`
      $ mix coherence.install --full-invitable

      # Install the `full` options except `lockable` and `trackable`
      $ mix coherence.install --full --no-lockable --no-trackable


  Run `$ mix help coherence.install` for more information.

### Clean

The following examples illustrate how to remove the files created by the installer:

      # Clean all the installed files
      $ mix coherence.clean --all

      # Clean only the installed view and template files
      $ mix coherence.clean --views --templates

      # Clean all but the models
      $ mix coherence.clean --all --no-models

      # Prompt once to confirm the removal
      $ mix coherence.clean --all --confirm-once


After installation, if you later want to remove one more options, here are a couple examples:

    # Clean one option
    $ mix coherence.clean --options=recoverable

    # Clean several options without confirmation
    $ mix coherence.clicked --no-confirm --options="recoverable unlockable-with-token"

    # Test the uninstaller without removing files
    $ mix coherence.clicked --dry-run --options="recoverable unlockable-with-token"

Run `$ mix help coherence.install` or `$ mix help coherence.install` for more information.
  """
  use Application
  alias Coherence.Config

  @doc false
  def start(_type, _args) do
    Coherence.Supervisor.start_link()
  end

  @doc """
  Get the currently logged in user data.
  """
  def current_user(conn), do: conn.assigns[Config.assigns_key]

  @doc """
  Check if user is logged in.
  """
  def logged_in?(conn), do: !!current_user(conn)
end
