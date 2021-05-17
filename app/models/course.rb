# == Schema Information
#
# Table name: courses
#
#  id               :bigint(8)        not null, primary key
#  name             :string
#  promotion_id     :bigint(8)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  description      :text
#  teach_project_id :integer
#  starting_at      :date
#

class Course < ApplicationRecord
  belongs_to :promotion
  has_many :achievements
  has_many :events
  has_many :evaluations

  QUALITY = [
    { title: '0-5', from: 0, to: 5 },
    { title: '5', from: 5, to: 6 },
    { title: '6', from: 6, to: 7 },
    { title: '7', from: 7, to: 8 },
    { title: '8', from: 8, to: 9 },
    { title: '9', from: 9, to: 10 }
  ]

  scope :done, -> { where('starting_at < ?', Date.today)}
  default_scope { order(:starting_at) }

  delegate :students, to: :promotion

  def self.for_promotion_with_quality(promotion, quality)
    list = []
    promotion.courses.each do |course|
      list << course if course.quality > quality[:from] && course.quality <= quality[:to]
    end
    list
  end

  def name_with_promotion
    "#{promotion} / #{to_s}"
  end

  def average_note
    total = student_notes.reduce(0, :+)
    1.0 * total / promotion.students.count
  end

  def median_note
    student_notes.sort[student_notes.count/2]
  end

  def student_notes
    # TODO store notes in database somehow, this is so slow
    @student_notes ||= promotion.students.map { |student| student.note_for_course(self) }
  end

  def points_total
    achievements.sum :points
  end

  def current?
    # TODO avant le cours suivant
    Date.today >= starting_at && Date.today < starting_at + 7.days
  end

  def done?
    Date.today > starting_at + 7.days
  end

  def quality
    rounded_average :quality
  end

  def knowledge_acquired
    rounded_average :knowledge_acquired
  end

  def technical_skills_acquired
    rounded_average :technical_skills_acquired
  end

  def soft_skills_acquired
    rounded_average :soft_skills_acquired
  end

  def to_s
    "#{name}"
  end

  protected

  def rounded_average(kind)
    evaluations.average(kind).to_f.round(2)
  end
end
