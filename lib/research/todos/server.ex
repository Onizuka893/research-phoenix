defmodule Research.Todos.Server do
  use GenServer

  require Logger
  alias Research.Todos.Context
  alias Phoenix.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def list_todos do
    GenServer.call(__MODULE__, :list_todos)
  end

  def get_todo(id) do
    GenServer.call(__MODULE__, {:get_todo, id})
  end

  def create_todo(attrs) do
    GenServer.call(__MODULE__, {:create_todo, attrs})
  end

  def update_todo(todo, attrs) do
    GenServer.call(__MODULE__, {:update_todo, todo, attrs})
  end

  def delete_todo(todo) do
    GenServer.call(__MODULE__, {:delete_todo, todo})
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:list_todos, _from, state) do
    task = Task.async(fn -> Context.list_todos() end)
    {:reply, Task.await(task), state}
  end

  @impl true
  def handle_call({:get_todo, id}, _from, state) do
    task = Task.async(fn -> Context.get_todo(id) end)
    {:reply, Task.await(task), state}
  end

  @impl true
  def handle_call({:create_todo, attrs}, _from, state) do
    Logger.info("hit create #{inspect(attrs)}")
    task = Task.async(fn -> Context.create_todo(attrs) end)
    response = Task.await(task)

    with {:ok, _todo} <- response do
      PubSub.broadcast(Research.PubSub, "todos", {:created, :todo})
    end

    {:reply, response, state}
  end

  # Example for update_todo
  @impl true
  def handle_call({:update_todo, todo, attrs}, _from, state) do
    task = Task.async(fn -> Context.update_todo(todo, attrs) end)
    response = Task.await(task)

    with {:ok, _updated_todo} <- response do
      PubSub.broadcast(Research.PubSub, "todos", {:updated, :todo})
    end

    {:reply, response, state}
  end

  # Example for delete_todo
  @impl true
  def handle_call({:delete_todo, todo}, _from, state) do
    task = Task.async(fn -> Context.delete_todo(todo) end)
    response = Task.await(task)

    with {:ok, _deleted_todo} <- response do
      PubSub.broadcast(Research.PubSub, "todos", {:deleted, :todo})
    end

    {:reply, response, state}
  end
end
