class SearchController < ApplicationController

  def quiz
    level = params[:level].to_i
    question = params[:question].sub(Search::LINE_ENDINGS_REGEXP, '')
    task_id = params[:id]

    AnswerJob.perform_async(level, question, task_id)

    head 200
  end

end
