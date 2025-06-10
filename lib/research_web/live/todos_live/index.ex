defmodule ResearchWeb.TodosLive.Index do
  use ResearchWeb, :live_view

  alias Research.Todos.Server
  alias Research.Todos.Todo
  alias Research.Todos

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to the :todos topic when the LiveView mounts
    if connected?(socket), do: Phoenix.PubSub.subscribe(Research.PubSub, "todos")

    # Fetch the initial list of todos directly from the GenServer
    todos = Server.list_todos()

    {:ok,
     socket
     |> assign(:todos, todos)
     |> assign(:form, to_form(Todos.change_todo(%Todo{})))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 flex items-center justify-center font-sans">
      <div class="w-full max-w-2xl p-4">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h1 class="card-title text-3xl mb-4">My Todos</h1>

            <div class="overflow-x-auto mb-6">
              <table class="table w-full">
                <thead>
                  <tr>
                    <th class="w-10">Status</th>
                    <th>Task</th>
                    <th class="w-24 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= if @todos == [] do %>
                    <tr>
                      <td colspan="3" class="text-center p-4">You have no todos yet!</td>
                    </tr>
                  <% end %>

                  <tr :for={todo <- @todos} class="hover">
                    <td>
                      <input
                        type="checkbox"
                        checked={todo.completed}
                        class="checkbox checkbox-primary"
                        phx-click="toggle_todo"
                        phx-value-id={todo.id}
                      />
                    </td>
                    <td class={if todo.completed, do: "line-through text-gray-500"}>
                      {todo.title}
                    </td>
                    <td class="text-center">
                      <button
                        class="btn btn-ghost btn-xs"
                        phx-click="delete_todo"
                        phx-value-id={todo.id}
                        phx-confirm="Are you sure?"
                      >
                        delete
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <h2 class="card-title text-xl mb-2">New Todo</h2>
            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
              <div class="form-control">
                <.input
                  field={@form[:title]}
                  placeholder="What needs to be done?"
                  class="input input-bordered w-full"
                />
              </div>

              <.button class="btn btn-primary w-full">
                <.icon name="hero-plus-circle" class="size-5 opacity-75 hover:opacity-100" /> Add Todo
              </.button>
            </.form>
          </div>
        </div>
        <p class="text-center text-xs mt-4 text-base-content/50">
          Research Project Volkan Ibis Phoenix
        </p>
      </div>
    </div>
    """
  end

  # --- Event Handlers (Directly calling the GenServer) ---

  @impl true
  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset = Ecto.Changeset.cast(%Todo{}, todo_params, [:title])
    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"todo" => todo_params}, socket) do
    case Server.create_todo(todo_params) do
      {:ok, _new_todo} ->
        # The PubSub message will handle the UI update.
        # We just need to reset the form.
        {:noreply,
         socket
         |> put_flash(:info, "Todo created successfully!")
         |> assign(:form, to_form(Todos.change_todo(%Todo{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Server.get_todo(id)

    case Server.delete_todo(todo) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Todo deleted!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete todo.")}
    end
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todo = Server.get_todo(id)
    new_status = !todo.completed

    case Server.update_todo(todo, %{completed: new_status}) do
      {:ok, _} ->
        # The PubSub message will handle the UI update
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update todo.")}
    end
  end

  # --- PubSub Message Handler ---

  @impl true
  def handle_info({:created, :todo}, socket) do
    # When a "created" message is received, refetch the list and update the view.
    todos = Server.list_todos()
    {:noreply, assign(socket, :todos, todos)}
  end

  @impl true
  def handle_info({:updated, :todo}, socket) do
    # You can add more specific logic, but refetching is simple and effective.
    todos = Server.list_todos()
    {:noreply, assign(socket, :todos, todos)}
  end

  @impl true
  def handle_info({:deleted, :todo}, socket) do
    todos = Server.list_todos()
    {:noreply, assign(socket, :todos, todos)}
  end
end
