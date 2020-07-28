defmodule Coda.Validations.Configuration do
  @moduledoc """
  Configuration parameters used by the validations
  TODO: Read these parameters from a file at application startup
  """

  def slot_time, do: 3 * 60 * 1000

  def grace_window(_state), do: 20 * 60 * 1000

  def acceptable_margin, do: 0.05

end
