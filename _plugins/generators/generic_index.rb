# Title: GenericIndexGenerator
# Original: https://github.com/rfelix/my_jekyll_extensions/blob/master/tag_gen/tag_gen.rb
# Description: Creates generic index pages

require 'inflection'

module Jekyll

  class GenericIndexIndex < Page
    def initialize(site, base, dir, type, page, config)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      # Use the already cached layout content and data for theme support
      self.content = @site.layouts[type].content
      self.data = @site.layouts[type].data

      page_title = page
      page_title = page.gsub(/(\w+)/) {|s| s.capitalize} if config["titleize"]

      self.data['title'] = "#{config["title_prefix"]}#{page_title}"
      self.data[config['page_type']] = page
      related(page, config) if config['related']

      self.process(@name)
    end

    def related(page, config)
      self.data['related'] = []

      site_coll = @site.send ::Inflection.plural(config['page_type'])
      site_coll[page].each do |post|
        post_coll = post.send ::Inflection.plural(config['page_type'])
        post_coll.each do |rel|
          self.data['related'].push(rel)
        end
      end

      self.data['related'] = self.data['related'].uniq
    end
  end

  class GenericIndexList < Page
    attr_accessor :page_type

    def initialize(site,  base, dir, type, pages, config)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      # Use the already cached layout content and data for theme support
      self.content = @site.layouts[type].content
      self.data = @site.layouts[type].data

      self.data[::Inflection.plural(config['page_type'])] = pages.keys.sort

      self.process(@name)
    end
  end

  class GenericIndexGenerator < Generator
    safe true

    def initialize(config)
      super
      return @enabled = false if @plugin_config.empty?

      config = {}
      @plugin_config.each do |page_type|
        c = {}
        if page_type.is_a?(Hash)
          page_type, c['related'] = page_type.shift
        elsif page_type.is_a?(Array)
          page_type, c = page_type
        end

        c ||= {}
        c = c.merge!({
          'related'    => false,
          'page_title' => page_type.capitalize + ': ',
          'dir'        => ::Inflection.plural(page_type),
          'page_type'  => page_type,
          'titleize'   => false,
        }){ |key, v1, v2| v1 }

        config[page_type] =  c
      end

      @plugin_config = config
    end

    def generate(site)
      return if !@enabled

      @plugin_config.each do |page_type, config|
        pages = site.send ::Inflection.plural(config['page_type'])
        next unless pages

        type = "generic_index/#{config['page_type']}/index"
        if site.layouts.key?(type)
          pages.keys.each do |page|
            write_index(site, File.join(config['dir'], page.to_s.gsub(/\s/, "-").gsub(/[^\w-]/, '').downcase), type, page, config)
          end
        end

        type = "generic_index/#{config['page_type']}/list"
        write_list(site, config['dir'], type, pages, config) if site.layouts.key?(type)
      end
    end

    def write_index(site, dir, type, page, config)
      index = GenericIndexIndex.new(site, site.source, dir, type, page, config)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.static_files << index
    end

    def write_list(site, dir, type, pages, config)
      index = GenericIndexList.new(site, site.source, dir, type, pages, config)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.static_files << index
    end
  end

end
