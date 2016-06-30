module UsersHelper
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user, options = { size: 50 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{options[:size]}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  # Returns a list of roles we have permission to assign
  def roles_for_select
    Role.all.select {|role| policy(role).add_user? }.sort.map {|r| [r.name.titleize, r.id] }
  end

  def institutions_for_select
    Institution.all.select {|institution| policy(institution).add_user? }
  end

  def generate_key_confirmation_msg(user)
    if user.encrypted_api_secret_key
      'Are you sure?  Your current API secret key will be destroyed and replaced with the new one.'
    else
      ''
    end
  end
end
