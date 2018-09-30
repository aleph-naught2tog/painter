defmodule Helpers.LogTestHelper do
  import ExUnit.Assertions
  import ExUnit.CaptureIO

  def assert_log(log_function) do
    assert capture_io(log_function)
  end

  def refute_log(log_function) do
    refute capture_io(log_function)
  end

  def assert_log_result(desired_result, log_function) do
    send_message_by(log_function)
    do_assert_receive {:result, desired_result}
  end

  def refute_log_result(desired_result, log_function) do
    send_message_by(log_function)
    do_refute_receive {:result, desired_result}
  end

  defp send_message_by(log_function) do
    current_pid = self()

    capture_io(fn ->
      result = log_function.()
      send(current_pid, {:result, result})
    end)
  end

  defp do_assert_receive(result), do: do_receive(result, :assert)
  defp do_refute_receive(result), do: do_receive(result, :refute)

  defp do_receive(desired_result, assert_or_refute) do
    receive do
      message ->
        case assert_or_refute do
          :assert -> assert message === desired_result
          :refute -> refute message === desired_result
        end
    after
      100 -> false
    end
  end
end