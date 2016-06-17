defmodule Productive.Step do

  alias Productive.StepError

  defmacro __using__( opts ) do
    quote do

      @any "any"
      @logger unquote(opts[:logger])

      def call( product, opts \\ [] ) do
        log_step __MODULE__, product

        product
        |> determine_state( opts )
        |> work( product, opts )
      end

      def determine_state( product, opts \\ [] ) do
        try do
          do_determine_state( product, opts )
        rescue
          FunctionClauseError -> raise StepError, "Error while resolving state for: #{inspect product}"
          MatchError          -> raise StepError, "Error while resolving state for: #{inspect product}"
        end
      end

      # Private ##########

      defp work( state, product, opts \\ [] ) do
        info "State resolved to: #{inspect state}"
        try do
          do_work( state, product, opts )
        rescue
          FunctionClauseError -> raise StepError, "Invalid state (#{inspect state}) or product: #{inspect product}"
          MatchError          -> raise StepError, "Invalid state (#{inspect state}) or product: #{inspect product}"
        end
      end

      #defp do_determine_state( _product, _opts ), do: raise("You must implement the do_determine_state function(s)")
      def do_determine_state( _recipe, _opts ), do: @any

      defp do_work( _state, _product, _opts ), do: raise("You must implement the do_work function(s)")

      defp log_step( module, product \\ %{} ) do
        step_name = Module.split( __MODULE__ )
                    #|> Enum.slice( 0, 100 )
                    |> Enum.join(".")

        step_info "[STEP] #{step_name}"
      end

      defp debug( msg ), do: apply( @logger, :debug, [msg] )
      defp info( msg ),  do: apply( @logger, :info, [msg] )
      defp error( msg ), do: apply( @logger, :error, [msg] )
      defp warn( msg ),  do: apply( @logger, :warn, [msg] )

      defp step_info( msg ), do: apply( @logger, :step_info, [msg] )

      defoverridable [
        do_determine_state: 2,
        do_work: 3
      ]

    end
  end

end
