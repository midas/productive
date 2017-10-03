defmodule Productive.Step do

  defmacro __using__( opts ) do
    quote do

      import Productive.Step.Utils

      @any "any"
      @logger unquote(opts[:logger])

      def call( product, opts \\ [] ) do
        log_step __MODULE__, product

        product
        |> do_prepare( opts )
        |> do_work( product, opts )
      end

      def do_prepare( product, opts \\ [] ) do
        prepare( product, opts )
      end

      # Private ##########

      defp do_work( state, product, opts \\ [] ) do
        state_info( inspect( state ))

        work( state, product, opts )
      end

      def prepare( _recipe, _opts ), do: @any

      defp work( _state, _product, _opts ), do: raise("You must implement the work function(s)")

      defp log_step( module, product \\ %{} ) do
        step_name = inspect( __MODULE__ )

        step_info step_name
      end

      defp debug( msg ), do: apply( @logger, :debug, [msg] )
      defp info( msg ),  do: apply( @logger, :info, [msg] )
      defp error( msg ), do: apply( @logger, :error, [msg] )
      defp warn( msg ),  do: apply( @logger, :warn, [msg] )

      defp step_info( msg ),  do: apply( @logger, :step_info,  [msg] )
      defp state_info( msg ), do: apply( @logger, :state_info, [msg] )

      defoverridable [
        log_step: 2,
        prepare: 2,
        work: 3
      ]

    end
  end

end
