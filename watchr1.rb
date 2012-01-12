# watch is the function provided by watchr
watch('lib/model/doctrine/(.*).php') { |m| code_changed(m[0]) }
def code_changed(file)
  puts("MODIFIED: #{file}")
end
