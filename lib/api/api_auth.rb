module ApiAuth

  protected

  # Determine whether or not a request should be handled as
  # an API request instead of a UI/browser request.
  def api_request?
    request.headers["X-Pharos-API-User"] && request.headers["X-Pharos-API-Key"]
  end

end
