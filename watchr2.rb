# Needed for displaying dates, used later on in the system call to growlnotify
require 'date'
# List of files to watch.
watch('lib/model/doctrine/(.*).php') { |m| code_changed(m[0]) }
watch('lib/(.*).php') { |m| code_changed(m[0]) }
watch('lib/form/(.*).php') { |m| code_changed(m[0]) }
watch('lib/form/doctrine/(.*).php') { |m| code_changed(m[0]) }
watch('lib/validator/(.*).php') { |m| code_changed(m[0]) }
watch('lib/widget/(.*).php') { |m| code_changed(m[0]) }
# what do when code is changed
def code_changed(file)
  # Array used to store the directorys that contain unit tests
  testDir = []
  testDir.push('test/unit')
  testDir.push('test/unit/model')
# Assume there won't be any errors
  error = false;
  # Go through all the test dir
  testDir.each do |test_dir|
    # select all *.php files from test dir
    test_dir_files = File.join("**",test_dir,"*.php")
    phpTestFiles = Dir.glob(test_dir_files)
    # For each PHP test file
    phpTestFiles.each do |phpTestFile|
      # run the system command php on each file
      if(!runCmdOnFile("php",phpTestFile))
      # The test had an error
        error = true;
      end
    end
  end
  # If there are no errors, let the user know
  if(!error)
    growl("All Passed")
  end
end
# command is run on a file and the output is parsed
def runCmdOnFile(cmd, file)
  if(cmd == "php")
  # we want to redirect stderr to stdout so that watchr can handle error messages
  # when the php interepreter itself barfs on our test code
  run_output = `#{cmd} #{file} 2>&1`
     if(checkMessage(run_output))
       return true
     else
       # Try to parse the message for errors
       errorMessage = parseError(run_output, file)
       growl(errorMessage)
       return false
     end
  end
end
# Simple check to see if the test passed
def checkMessage(run_output)
  if run_output.include?("# Looks like everything went fine.")
    return true
  else
    return false
  end
end
# Try to figure out what went wrong when the program was executed
def parseError(run_output, file)
  # Array to contain the error message
  errorMessage = []
  # First, note the name of the test that failed
  errorMessage.push("#{file}\n \n")
  output = []
  output = run_output.split("\n")
  run_output = output;
  # Look through the output for common errors.
  # This can be expanded as new problems arise
  run_output.each do |line|
    if(line =~ /# Looks like you planned/)
      errorMessage.push("You probably forgot to update lime_test.\n")
    end
    if(line =~ /not ok/)
      errorMessage.push("Test Failed\n")
    end
    # This is real bad, the php interpreter barfed on the code
    if( line =~ /PHP Fatal error/)
      errorMessage.push(line + "\n")
    end
  end
  return errorMessage;
end
# Function to send messages to user via growl
def growl(message)
  # Check to see if the message is a "All Passed" signal
  # and set the image accordingly
  if(message.include?("All Passed"))
    image = "~/.watchr/images/passed.png"
    # Set the passed flag to true
    passed = true
  else
    # There was some kind of error
    image = "~/.watchr/images/failed.png"
  end
  # Transform any messages that are strings into an array
  if(!message.kind_of?(Array))
    messageArray = []
    messageArray.push(message + "\n")
    message = messageArray;
  end
  # If the error output of test is too long,
  # growlnotify will break. Limit the message to the first 2
  message = message.first(2);
  message.push("\n")
  # Timestamp our message
  message.push(Time.now.asctime)
  # Where does your growlnotify live? "which growlnotify" will tell you
  growlnotify = '/usr/local/bin/growlnotify'
  # Options to pass to growlnotify
  if(passed)
    # Let's not make an "All Passed" signal sticky.. better to just reassure the
    # user everything is ok when a file is saved
    options = "-n Watchr -m '#{message}' --image #{image}"
  else
    # If there is an error, make it persist so that the user has to least acknowledge it
    options = "-s -n Watchr -m '#{message}' --image #{image}"
  end
  # Make the system call to growlnotify
  system("#{growlnotify} #{options}")
  return true
end
