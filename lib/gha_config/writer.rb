require 'fileutils'

module GhaConfig
  module Writer
    def self.write(config, output_file)
      output_hash = {}
      output_hash['name'] = 'CI'
      output_hash['on'] = config.parsed_config['on']

      default_env =  {
        'SLACK_CHANNEL' => ''
      }
      output_hash['env'] = default_env.merge(config.env).
        merge({
                'HOME'                  => '/home/circleci',
                'AWS_ACCESS_KEY_ID'     => '${{ secrets.AWS_ACCESS_KEY_ID }}',
                'AWS_ACCOUNT_ID'        => '${{ secrets.AWS_ACCOUNT_ID }}',
                'AWS_REGION'            => '${{ secrets.AWS_REGION }}',
                'AWS_SECRET_ACCESS_KEY' => '${{ secrets.AWS_SECRET_ACCESS_KEY }}',
      })

      output_hash['jobs'] = {}
      config.parsed_config['jobs'].each do |name, job|
        new_job = {
          'runs-on' => '[ubuntu, runner-fleet]'
        }
        job['runs-on'] = '[ubuntu, runner-fleet]'
        flipp_global = {
          'name' => 'Flipp global',
          'uses' => 'wishabi/wishabi/my-cool-action',
		}
        job['steps'].unshift(flipp_global)
        checkout = {
          'name' => 'Checkout code',
          'uses' => 'actions/checkout@v2'
        }
        if config.options['use_submodules']
          checkout['with'] = {
            'token' => "${{ secrets.FLIPPCIRCLECIPULLER_REPO_TOKEN }}",
            'submodules' => 'recursive'
          }
        end
        job['steps'].unshift(checkout)
        job['needs'] = "[#{job['needs'].join(', ')}]" if job['needs'].is_a?(Array)
        new_job.merge!(job)
        output_hash['jobs'][name] = new_job
      end
      output = output_hash.to_yaml
      output = cleanup(output, config)
      header = <<-OUT
######## GENERATED FROM ./github/workflow-src/CI.yml
######## USING gha_config https://github.com/wishabi/gha-config

      OUT
      output = header + output
      FileUtils.mkdir_p(File.dirname(output_file))
      File.write(output_file, output)
    end

    def self.cleanup(out, config)
      out = out.sub("---\n", '')
      out = out.gsub(/'on'/, 'on') # replace 'on' with on
      out = out.gsub(/: ''/, ':') # replace : '' with :
      out = out.gsub(/\n(\S)/) { "\n\n#{$1}" } # add empty line before top level keys
      out = out.gsub(/"\[/, '[')
      out = out.gsub(/\]"/, ']') # change "[...]" to [...]

      config.variables.each do |name, val|
        out = out.gsub("__#{name}__", val)
      end

      first, last = out.split("\njobs:")
      first = first.gsub(/"/, '') # remove quotes from env block
      last = last.gsub(/\n  (\S)/) { "\n\n  #{$1}" } # add empty line before job keys
      out = first + "\njobs:" + last

      out
    end

  end
end
