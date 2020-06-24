defmodule ApiWeb.Resolvers.QuestionResolver do
  alias Api.Generator.{QuestionGenerator, NumberGenerator}
  alias Api.Questions

  defp get_random_question() do
    question = QuestionGenerator.generate_question()

    db_result =
      question
      |> Map.get(:text)
      |> Questions.get_question_by_text()

    cond do
      db_result == nil ->
        %{
          answer: Map.get(question, :answer),
          text: Map.get(question, :text)
        }
        |> Questions.create_question()

        question
        |> Map.get(:text)
        |> Questions.get_question_by_text()

      db_result != nil ->
        db_result
    end
  end

  def get_false_answers(answers, amount, correct) do
    case length(answers) < amount do
      true ->
        number = NumberGenerator.generate_number(-100, 100)

        case number != correct && !Enum.member?(answers, number) do
          true ->
            [number | answers]
            |> get_false_answers(amount, correct)

          _ ->
            get_false_answers(answers, amount, correct)
        end

      _ ->
        answers
    end
  end

  defp get_random_questions(array, count) do
    case count > 0 do
      true ->
        question = get_random_question()

        question =
          Map.put(question, :false_answers, get_false_answers([], 3, Map.get(question, :answer)))

        [question | array]
        |> get_random_questions(count - 1)

      _ ->
        array
    end
  end

  def questions(_parent, args, _resolution) do
    cond do
      Map.get(args, :random) == true && Map.has_key?(args, :amount) ->
        {:ok, get_random_questions([], Map.get(args, :amount))}

      Map.has_key?(args, :id) ->
        try do
          {
            :ok,
            args
            |> Map.get(:id)
            |> Questions.get_question!()
          }
        rescue
          _e in Ecto.NoResultsError ->
            {:error, "The question belonging to this id can not be found"}
        end

      true ->
        {:error, "Can not resolve combination of parameters"}
    end
  end
end
