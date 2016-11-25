defmodule Productive.Step.Utils do

  def add_errors( product, errors ) do
    errors = List.wrap( errors )

    product
    |> Map.put( :errors, (errors ++ product.errors) )
  end

  def add_halted_status( product, status ) do
    product
    |> Map.put( :halted_status, status )
  end

  def add_status_and_halt!( product, status ) do
    product
    |> add_halted_status( status )
    |> halt!
  end

  def add_errors_and_halt!( product, errors ) do
    product
    |> add_errors( errors )
    |> halt!
  end

  def halt!( product ) do
    product
    |> Map.put( :halted, true )
  end

end
