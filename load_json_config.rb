#!/usr/bin/env ruby

require 'json'
require 'diplomat'
def iterate(h,path)
  h.each do |k,v|
    value = v || k
    if value.is_a?(Hash)
      iterate(value,"#{path}/#{k}")
    elsif value.is_a?(Array)
      begin
        temparray=[]
        value.each do |a|
          if !a.is_a?(Hash)
            temp=Diplotmat::Kv.get("#{path}/#{k}")
            if temp != value.to_s
              Diplomat::Kv.put("#{path}/#{k}", "#{value}")
            end
          else
            temparray.push({k => a.to_json})
          end
        end
        if temparray.length > 0
          vals=[]
          temparray.each do |t|
            vals.push("#{t.values.first}")
          end
          iterate({temparray.first.keys.uniq.first => "#{vals}"}, "#{path}")
        end
      rescue
        Diplomat::Kv.put("#{path}/#{k}", "#{value}")
      end
    else
      begin
        temp=Diplomat::Kv.get("#{path}/#{k}")
        if temp != v
          Diplomat::Kv.put("#{path}/#{k}", "#{v}")
        end
      rescue
        if v.instance_of?(String) and v =~ /\[|\]/
          v=v.to_a
        end
        Diplomat::Kv.put("#{path}/#{k}", "#{v}")
      end
    end
  end
end

input_array=ARGV[0].split('.')
raw_filename=input_array[0...-1].join('.')
filename = "<%= @config_base_path %>/<%= @appname %>/control/#{ARGV[0]}"
consul_path = "<%= scope.lookupvar('::env') %>/<%= @appname %>/config_files/#{raw_filename}"

data=JSON.parse(File.open(filename).read)
iterate(data,consul_path)


