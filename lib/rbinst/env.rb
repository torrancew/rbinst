require 'open3'

module RbInst
  class Env
    attr_reader :plugins

    def initialize(envfile='./Envfile')
      path(ENV['HOME'] + '.rbenv')
      source('https://github.com')

      @plugins = Hash.new
      @envfile = File.expand_path(envfile)

      raise 'Envfile not present!' unless File.exists?(@envfile)
      instance_eval(File.read(@envfile), @envfile, 1)
    end

    def directory_exists?(path)
      return (File.exists?(path) && File.directory?(path))
    end

    def git_checkout(url, path, ref=nil)
      status = nil
      cmd    = Array.new

      cmd << 'git clone'
      cmd << "-b #{ref}" if ref
      cmd << url
      cmd << path

      Open3.popen3(ENV, cmd.join(' ')){ |i, o, e, t| status = t.value }

      return status == 0
    end

    def install_plugins
      @plugins.each do |name, opts|
        git_dir  = opts[:git_dir]
        base_dir = File.dirname(git_dir)

        unless directory_exists?(git_dir)
          $stdout.puts "Fetching #{name} from #{opts[:git]}"
          git_checkout(opts[:git], base_dir, opts[:ref])
        end
      end
    end

    def install_rbenv
      git_url  = 'https://github.com/sstephenson/rbenv.git'
      git_dir  = File.join(@path, '.git')
      base_dir = File.dirname(git_dir)

      unless directory_exists?(git_dir)
        $stdout.puts "Fetching rbenv from #{git_url}"
        git_checkout(git_url, base_dir)
      end
    end

    def path(p)
      @path = File.expand_path(p)
    end

    def plugin(plugin_name, opts={})
      name = safe_name(plugin_name)
      opts = {
        :ref     => nil,
        :git     => File.join(@source, plugin_name),
        :git_dir => File.join(@path, 'plugins', name, '.git'),
      }.merge(opts)
      @plugins[name.to_sym] = opts
    end

    def safe_name(name)
      return name.split('/').last.gsub(/\s+/, '_')
    end

    def source(url)
      @source = url
    end
  end
end
