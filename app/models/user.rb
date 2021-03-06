class User < ActiveRecord::Base
	attr_accessor :remember_token, :activation_token, :reset_token
	before_save :downcase_email
	before_create :create_activation_digest
	before_save { self.email = email.downcase}
	validates :name, presence: true, length: { maximum: 50}
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, length: { maximum: 255},
	format: { with: VALID_EMAIL_REGEX},
	uniqueness: {case_sensitive: false}
	has_secure_password
	validates :password, length: { minimum: 6}, allow_blank: true

	has_many :microposts, dependent: :destroy
	def User.digest(string)
		cost = ActiveModel::SecurePasswod.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost

		BCrypt::Password.create(string, cost: cost)
	end

	def authenticated?(attribute, token)
		digest = send("#{attribute}_digest")
		return false if remember_digest.nil?
		BCrypt::Password.new(digest).is_password?(token)
	end

	def create_activation_digest
		self.activation_token = User.new_token
		self.activation_digest = User.digest(activation_token)
	end

	def create_reset_digest
		self.reset_token = User.new_token
		update_attribute(:reset_digest, User.digest(reset_token))
		update_attribute(:reset_sent_at, Time.zone.now)
	end

	def send_password_reset_email
		UserMailer.password_reset(self).deliver_now
	end

	def password_reset_expired?
		reset_sent_at < 2.hours.ago
	end

	def feed
		Micropost.where("user_id = ?", id)
	end
end
