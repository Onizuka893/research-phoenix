defmodule Research.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ResearchWeb.Telemetry,
      Research.Repo,
      {DNSCluster, query: Application.get_env(:research, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Research.PubSub},
      {Task.Supervisor, name: Research.TaskSupervisor},
      {Registry, keys: :unique, name: TodoRegistry},
      Research.Todos.Server,
      # Supervisor.child_spec(
      #   {Research.Todos.Server, name: {:via, Registry, {TodoRegistry, :server_1}}},
      #   id: :server_1
      # ),
      # Supervisor.child_spec(
      #   {Research.Todos.Server, name: {:via, Registry, {TodoRegistry, :server_2}}},
      #   id: :server_2
      # ),
      # Supervisor.child_spec(
      #   {Research.Todos.Server, name: {:via, Registry, {TodoRegistry, :server_3}}},
      #   id: :server_3
      # ),
      # Start a worker by calling: Research.Worker.start_link(arg)
      # {Research.Worker, arg},
      # Start to serve requests, typically the last entry
      ResearchWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Research.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ResearchWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def pick_random_server do
    servers =
      Registry.lookup(TodoRegistry, :server_1) ++
        Registry.lookup(TodoRegistry, :server_2) ++
        Registry.lookup(TodoRegistry, :server_3)

    {pid, _} = Enum.random(servers)
    pid
  end
end
