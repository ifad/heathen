require 'digest/sha2'

# checks if the uploaded file has already been processed,
# and returns an identical dragonfly job, or a new job
class Inquisitor

  attr_reader :app

  def initialize(app)
    @app = app
  end

  def find(file)

    job = nil
    key = content_hash(file[:tempfile])

    if serialized = app.redis[key]
      job = Dragonfly::Job.deserialize(serialized, app.converter)   
    else
      job = app.converter.new_job(file[:tempfile], name: file[:filename])
      job = job.fetch(job.store)
      app.redis[key] = job.serialize
    end

    job
  end

  private

    def content_hash(file)
      Digest::SHA2.file(file).hexdigest
    end
end
