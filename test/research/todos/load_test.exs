defmodule Research.Todos.LoadTest do
  use ExUnit.Case, async: true

  alias Research.Repo
  alias Research.Todos.Server
  alias Research.Todos.Todo

  @tag :load_test
  test "simulates 10 users creating 100 todos each and measures the time" do
    # --- 1. Setup ---
    # Ensure a clean slate before the test runs
    Repo.delete_all(Todo)

    num_users = 10
    todos_per_user = 100
    total_todos = num_users * todos_per_user

    IO.puts("""
    Starting load test...
    - Simulating #{num_users} concurrent users.
    - Each user creating #{todos_per_user} todos.
    - Total operations: #{total_todos}.
    ---
    """)

    # --- 2. Execution and Timing ---
    # :timer.tc measures the time taken and returns {microseconds, result}
    {time_in_microseconds, _results} =
      :timer.tc(fn ->
        # Create a list of async tasks, where each task represents a "user"
        tasks =
          Enum.map(1..num_users, fn user_id ->
            Task.async(fn ->
              # Each user creates their batch of todos
              Enum.each(1..todos_per_user, fn todo_num ->
                todo_title = "User #{user_id} - Todo #{todo_num}"

                # This calls our GenServer client API
                case Server.create_todo(%{title: todo_title}) do
                  {:ok, _} ->
                    :ok

                  {:error, changeset} ->
                    # Fail the test if any single operation fails
                    flunk("Failed to create todo. Changeset: #{inspect(changeset)}")
                end
              end)
            end)
          end)

        # Wait for all the tasks to complete. Timeout after 2 minutes.
        Task.await_many(tasks)
      end)

    # --- 3. Verification and Reporting ---
    # Verify that the correct number of todos exist in the database
    final_count = Repo.aggregate(Todo, :count, :id)
    assert final_count == total_todos

    # Report the results
    time_in_ms = time_in_microseconds / 1000
    time_in_seconds = time_in_microseconds / 1_000_000
    ops_per_second = total_todos / time_in_seconds

    IO.puts("""
    ---
    Load Test Finished!

    Results:
      - Total Time: #{Float.round(time_in_ms, 2)} ms (#{Float.round(time_in_seconds, 2)} s)
      - Throughput: #{Float.round(ops_per_second, 2)} creations/sec

    Assertion successful: #{final_count} todos were created in the database.
    """)
  end
end
