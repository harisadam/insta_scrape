require "dependencies"

module InstaScrape
  extend Capybara::DSL

  #get a hashtag
  def self.hashtag(hashtag)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    @posts = []
    scrape_posts
  end

  #get user info
  def self.user_info(username)
    scrape_user_info(username)
    @user = InstagramUser.new(username, @image, @post_count, @follower_count, @following_count, @description)
  end

  #get user info and posts
  def self.user_info_and_posts(username)
    scrape_user_info(username)
    scrape_user_posts(username)
    @user = InstagramUserWithPosts.new(username, @image, @post_count, @follower_count, @following_count, @description, @posts)
  end

  #get user posts only
  def self.user_posts(username)
    scrape_user_posts(username)
  end

  def self.user_follower_count(username)
    scrape_user_info(username)
    return @follower_count
  end

  def self.user_following_count(username)
    scrape_user_info(username)
    return @following_count
  end

  def self.user_post_count(username)
    scrape_user_info(username)
    return @post_count
  end

  def self.user_description(username)
    scrape_user_info(username)
    return @description
  end

  private
  #post iteration method
  def self.iterate_through_posts
    all("article div div div a").each do |post|

      link = post["href"]
      image = post.find("img")["src"]
      info = InstagramPost.new(link, image)
      @posts << info

    end

    #log
    puts "POST COUNT: #{@posts.length}"
    self.log_posts
    #return result
    return @posts
  end

  #user info scraper method
  def self.scrape_user_info(username)
    visit "https://www.instagram.com/#{username}/"
    @image = page.find('article header div img')["src"]
    within("header") do
      post_count_html = page.find('span', :text => "posts", exact: true)['innerHTML']
      @post_count = get_span_value(post_count_html)
      follower_count_html = page.find('span', :text => "followers", exact: true)['innerHTML']
      @follower_count = get_span_value(follower_count_html)
      following_count_html = page.find('span', :text => "following", exact: true)['innerHTML']
      @following_count = get_span_value(following_count_html)
      description = page.find('h2').first(:xpath,".//..")['innerHTML']
      @description = Nokogiri::HTML(description).text
    end
  end

  #scrape posts
  def self.scrape_posts
    begin
      page.find('a', :text => "Load more", exact: true).click
      max_iteration = 10
      iteration = 0
      while iteration < max_iteration do
        iteration += 1
        5.times { page.execute_script "window.scrollBy(0,10000)" }
        sleep 0.2
      end
      iterate_through_posts
    rescue Capybara::ElementNotFound => e
      begin
        iterate_through_posts
      end
    end
  end

  def self.scrape_user_posts(username)
    @posts = []
    visit "https://www.instagram.com/#{username}/"
    scrape_posts
  end

  #post logger
  def self.log_posts
    @posts.each do |post|
      puts "\n"
      puts "Image: #{post.image}\n"
      puts "Link: #{post.link}\n"
    end
    puts "\n"
  end

  #split away span tags from user info numbers
  def self.get_span_value(element)
    begin_split = "\">"
    end_split = "</span>"
    return element[/#{begin_split}(.*?)#{end_split}/m, 1]
  end

end
