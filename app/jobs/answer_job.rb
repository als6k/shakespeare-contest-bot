require 'benchmark'
require 'net/http'

ANSWER_URL = 'https://shakespeare-contest.rubyroidlabs.com/quiz'.freeze

class AnswerJob
  include SuckerPunch::Job

  def perform(level, question, task_id)
    requested_at = Time.current
    Rails.logger.info "---< Task: #{task_id}, Question: \"#{question.gsub("\n", '\n')}\" (#{level})"

    if question.blank? || level.blank? || task_id.blank?
      Rails.logger.info "!!! invalid params #{params.inspect}"
    else
      ActiveRecord::Base.connection_pool.with_connection do
        answer = nil

        time = Benchmark.measure do
          answer = Search.find(question, level)
        end

        if answer
          Rails.logger.info "---> Task: #{task_id}, Answer: \"#{answer}\" (#{level}) - #{time.real.round(5)}"
          server_response = send_answer(answer, task_id) if Rails.env.production?
        else
          Rails.logger.info "---> Task: #{task_id}, Not found: \"#{question.gsub("\n", '\n')}\" (#{level})"
        end

        Log.create(
          task_id: task_id,
          level: level,
          question: question,
          answer: answer,
          search_time: time.real.round(5),
          server_response: server_response,
          created_at: requested_at
        )
      end
    end
  end

  private

  def send_answer(answer, task_id)
    uri = URI(ANSWER_URL)
    parameters = {
      answer: answer,
      token: Rails.application.credentials.quiz_api_key,
      task_id: task_id
    }
    response = Net::HTTP.post_form(uri, parameters)
    message = JSON.parse(response.body)['message'] rescue response.body
    Rails.logger.info "---< Task: #{task_id}, #{message}"
    message
  end
end
