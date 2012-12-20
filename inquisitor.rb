require 'digest/sha2'

# checks if the uploaded file has already been processed,
# and returns an identical dragonfly job, or a new job
class Inquisitor

  attr_reader :redis
  attr_reader :converter

  def initialize(converter)
    @redis     = Heathen::App.redis
    @converter = converter
  end

  def find(file)

    job = nil
    key = content_hash(file[:tempfile])

    if serialized = redis[key]
      job = converter.job_class.deserialize(serialized, converter)   
    else
      job = converter.new_job(file[:tempfile], name: file[:filename])
      uid = job.store
      job = job.fetch(uid)
      redis[key] = job.serialize
    end

    job
  end

  private

    def content_hash(file)
      Digest::SHA2.file(file).hexdigest
    end
end
