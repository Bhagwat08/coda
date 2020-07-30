defmodule Coda.Validations.BlockProductionRate do
  @moduledoc """
  Validates that a block producer's block production rate matches is within an acceptable_margin of
  the expected rate.
  """

  use Architecture.Validation

  import Coda.Validations.Configuration

  require Logger

  # TODO: a dummy value; instead, calculate dynamically from running network
  defp expected_win_rate(_stake_ratio), do: 0.10

  @impl true
  def statistic, do: Coda.Statistics.BlockProductionRate

  @impl true
  def validate({Coda.Statistics.BlockProductionRate,_resource}, state) do
    IO.puts "VALIDATOR FOR BLOCK PRODUCTION RATE"
    # implication
    if state.elapsed_time < grace_window(state) do
      :valid
    else
      # BUG: no field elapsed_ns
      slots_elapsed = state.elapsed_ns / (slot_time())
      slot_production_ratio = state.blocks_produced / slots_elapsed

      # putting the call to acceptable_margin() here make dialyzer happy
      margin = acceptable_margin()

      cond do
        slot_production_ratio >= 1 ->
	  IO.puts "CASE 1"
          {:invalid, "unexpected, slot production ratio is 1 or greater"}

        # BUG: no field stake_ratio
        slot_production_ratio < expected_win_rate(state.stake_ratio) - margin ->
	  IO.puts "CASE 2"
          {:invalid, "not producing enough blocks"}

        slot_production_ratio > expected_win_rate(state.stake_ratio) + margin ->
	  IO.puts "CASE 3"
          {:invalid, "producing more blocks than expected"}

        true ->
	  IO.puts "CASE 4"
          :valid
      end
    end
  end
end
