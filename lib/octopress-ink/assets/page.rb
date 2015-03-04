# These are files which need to be in added to the root of the site directory
# Use root assets for files like robots.text or favicon.ico

module Octopress
  module Ink
    module Assets
      class PageAsset < Asset
        attr_reader :filename
        attr_accessor :data, :permalink_name, :cloned, :clone_of

        def initialize(plugin, base, file)
          @root = plugin.assets_path
          @plugin = plugin
          @base = base
          @filename = file
          @dir  = File.dirname(file)
          @file = File.basename(file)
          @exists = {}
          @permalink_name = file.sub(File.extname(file), '')
          @data = {}
          file_check
        end

        # Add page to Jekyll pages if no other page has a conflicting destination
        #
        def add
          if page.url && !find_page(page)
            Octopress.site.pages << page
            plugin.config['permalinks'] ||= {}
            permalink_config ||= page.url
          end
        end

        def clone(data={})
          self.cloned = true
          p = PageAsset.new(plugin, base, file)
          p.clone_of = self
          p.data = data
          p
        end

        def merge_data(data={})
          page.data.merge!(data)
        end

        def deep_merge(data={})
          Jekyll::Utils.deep_merge_hashes(page.data, data)
        end

        def find_page(page)
          site_dir = Octopress.site.dest
          dest = page.destination(site_dir)

          Octopress.site.pages.clone.each do |p|
            return p if p.destination(site_dir) == dest
          end
          return false
        end

        def page
          @page ||= begin
            page = Page.new(Octopress.site, source_dir, page_dir, file)

            if permalink_config
              page.data['permalink'] = permalink_config
            else
              permalink = page.data['permalink']
            end

            page.data.merge!(@data)
            page.plugin = plugin

            page
          end
        end

        def info
          message = super

          unless disabled?
            if clone_of
              "     #{permalink}"
            elsif cloned
              message << "\n     #{permalink}"
            else
              name = permalink_name << page.ext
              message.sub!(/#{filename}\s*/, name.ljust(35))
              message.ljust(25) << permalink
            end
          end

          message
        end

        def permalink
          page.url
        end
        
        def url; permalink; end

        def lang
          data['lang']
        end

        def permalink=(url)
          page.data['permalink'] = url
          permalink_config = url
        end

        def permalink_config
          if Octopress.multilingual? && lang
            plugin.config(lang)['permalinks'][permalink_name]
          else
            plugin.config['permalinks'][permalink_name]
          end
        end

        def permalink_config=(url)
          if permalink_name
            plugin.config['permalinks'][permalink_name] = url
          end
        end

        private

        def page_dir
          dir == '.' ? '' : dir
        end

        def plugin_path
          File.join(plugin_dir, dir, file)
        end

        def user_dir
          File.join Plugins.custom_dir, plugin.slug, base
        end

      end
    end
  end
end
