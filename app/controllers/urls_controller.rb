class UrlsController < ApplicationController
  @@urls = {}

  def create
    long_url = params[:long_url]
    custom_alias = params[:custom_alias]
    ttl_seconds = params[:ttl_seconds] || 120

    alias_key = custom_alias || generate_unique_alias
    short_url = URI.join(request.original_url, '/').to_s + alias_key
    @@urls[alias_key] = {
      original_url: long_url,
      short_url: short_url,
      ttl: ttl_seconds,
      created_at: Time.zone.now,
      access_times: []
    }

    render json: {
      short_url: short_url,
      ttl: ttl_seconds,
      created_at: Time.zone.now
    }, status: :created
  end

  def update
    key = params[:alias]
    new_alias = params[:custom_alias]
    new_ttl = params[:ttl_seconds]

    entry = @@urls[key]
    if entry.present?
      if new_alias.present?
        @@urls.delete(key)
        entry[:access_times] = []
      end
      entry[:ttl] = new_ttl if new_ttl.present?
      @@urls[new_alias] = entry
    else
      render json: { error: 'Not Found: Alias  does not exist or has expired.' }
    end
  end

  def redirect
    key = params[:alias]
    entry = @@urls[key]

    if entry.present?
      entry[:access_times] << Time.zone.now
      redirect_to entry[:original_url]
    else
      render json: { error: 'Not Found: Alias does not exist or has expired.' }
    end
  end

  def analytics
    key = params[:alias]
    entry = @@urls[key]

    if entry.present?
      render json: {
        alias: key,
        long_url: entry[:original_url],
        access_count: entry[:access_times].count,
        access_times: entry[:access_times].last(10)
      }
    else
      render json: { error: 'URL not found' }
    end
  end

  def destroy
    key = params[:alias]
    entry = @@urls[key]

    if entry.present?
      @@urls.delete(key)
    else
      render json: { error: 'Not Found: Alias does not exist or has expired.' }
    end
  end

  private

  def generate_unique_alias
    SecureRandom.urlsafe_base64
  end
end
