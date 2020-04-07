#
# Copyright (c) 2008-2020 the Urho3D project.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'pathname'
require 'json'
require 'yaml'

### Tasks for general users ###

# Usage: rake scaffolding dir=/path/to/new/project/root [project=Scaffolding] [target=Main]
desc 'Create a new project using Urho3D as external library'
task :scaffolding do
  abort 'Usage: rake scaffolding dir=/path/to/new/project/root [project=Scaffolding] [target=Main]' unless ENV['dir']
  project = ENV['project'] || 'Scaffolding'
  target = ENV['target'] || 'Main'
  abs_path = scaffolding ENV['dir'], project, target
  puts "\nNew project created in #{abs_path}.\n\n"
  puts "In order to configure and generate your project build tree you may need to first set"
  puts "'URHO3D_HOME' environment variable or use 'URHO3D_HOME' build option to point to the"
  puts "Urho3D project build tree or custom Urho3D SDK installation location.\n\n"
  puts "Please see https://urho3d.github.io/documentation/HEAD/_using_library.html for more detail.\nFor example:\n\n"
  puts "$ cd #{abs_path}\n$ rake cmake URHO3D_HOME=/path/to/Urho3D/build-tree\n$ rake make\n\n"
end

# Usage: rake cmake [<generator>] [<platform>] [<option>=<value> [<option>=<value>]] [[<platform>_]build_tree=/path/to/build-tree] [fix_scm]
# e.g.: rake cmake clean android; or rake cmake android URHO3D_LIB_TYPE=SHARED; or rake cmake ios URHO3D_LUA=1 build_tree=~/ios-Build
#
# To avoid repeating the customized build tree locations, you can set and export them as environment variables.
# e.g.: export native_build_tree=~/custom-native-Build android_build_tree=~/custom-android-Build mingw_build_tree=~/custom-mingw-Build rpi_build_tree=~/custom-rpi-Build
#       rake cmake rpi URHO3D_LUAJIT=1 URHO3D_LUAJIT_AMALG=1 && rake make rpi
#       The RPI build tree will be generated in the ~/custom-rpi-Build and then build from there
desc 'Invoke one of the build scripts with the build tree location predetermined based on the target platform'
task :cmake do
  script = 'cmake_generic'
  platform = 'native'
  build_options = ''
  File.readlines('script/.build-options').each { |var|
    var.chomp!
    ARGV << "#{var}=\"#{ENV[var]}\"" if ENV[var] && !ARGV.find { |arg| /#{var}=/ =~ arg }
  }
  ARGV.each { |option|
    task option.to_sym do ; end; Rake::Task[option].clear   # No-op hack
    case option
    when 'cmake', 'generic'
      # do nothing
    when 'clean', 'codeblocks', 'codelite', 'eclipse', 'ninja', 'vs2015', 'vs2017', 'vs2019', 'xcode'
      script = "cmake_#{option}" unless script == 'cmake_clean'
    when 'android', 'arm', 'ios', 'tvos', 'mingw', 'rpi', 'web'
      platform = option
      build_options = "#{build_options} -D#{option.upcase}=1" unless script == 'cmake_clean'
      script = 'cmake_xcode' if /(?:i|tv)os/ =~ option && script != 'cmake_clean'
      script = 'cmake_mingw' if option == 'mingw' && ENV['OS'] && script != 'cmake_clean'
    when 'fix_scm'
      build_options = "#{build_options} --fix-scm" if script == 'cmake_eclipse'
    else
      build_options = "#{build_options} -D#{option}" unless /build_tree=.*/ =~ option || script == 'cmake_clean'
    end
  }
  build_tree = ENV["#{platform}_build_tree"] || ENV['build_tree'] || "build/#{platform}"
  if ENV['OS']
    # CMake claims mingw32-make does not build correctly with MSYS shell in the PATH env-var and prevents build tree generation if so
    # Our CI on Windows host requires MSYS shell, so we cannot just simply remove it from the PATH globally
    # Instead, we modify the PATH env-var locally here just before invoking the CMake generator
    ENV['PATH'] = ENV['PATH'].gsub /Git\\usr\\bin/, 'GoAway'
  else
    ccache_envvar = ENV['CCACHE_SLOPPINESS'] ? '' : 'CCACHE_SLOPPINESS=pch_defines,time_macros'   # Only attempt to do the right thing when user hasn't done it
    ccache_envvar = "#{ccache_envvar} CCACHE_COMPRESS=1" unless ENV['CCACHE_COMPRESS']
  end
  system "#{ccache_envvar} script/#{script}#{ENV['OS'] ? '.bat' : '.sh'} \"#{build_tree}\" #{build_options}" or abort
end

# Usage: rake make [<platform>] [<option>=<value> [<option>=<value>]] [[<platform>_]build_tree=/path/to/build-tree] [numjobs=n] [clean_first] [unfilter]
# e.g.: rake make android; or rake make android doc; or rake make ios config=Debug sdk=iphonesimulator build_tree=~/ios-Build
desc 'Build the generated project in its corresponding build tree'
task :make do
  numjobs = ENV['numjobs'] || ''
  platform = 'native'
  cmake_build_options = ''
  build_options = ''
  unfilter = false
  ['config', 'target', 'sdk', 'ARCHS', 'ARGS', 'unfilter', 'verbosity'].each { |var|
    ARGV << "#{var}=\"#{ENV[var]}\"" if ENV[var] && !ARGV.find { |arg| /#{var}=/ =~ arg }
  }
  ARGV.each { |option|
    task option.to_sym do ; end; Rake::Task[option].clear   # No-op hack
    case option
    when 'codeblocks', 'codelite', 'eclipse', 'generic', 'make', 'ninja', 'vs2015', 'vs2017', 'vs2019', 'xcode'
      # do nothing
    when 'android', 'arm', 'ios', 'tvos', 'mingw', 'rpi', 'web'
      platform = option
    when 'clean_first'
      cmake_build_options = "#{cmake_build_options} --clean-first"
    when 'unfilter'
      unfilter = true
    else
      if /(?:config|target)=.*/ =~ option
        cmake_build_options = "#{cmake_build_options} --#{option.gsub(/=/, ' ')}"
      elsif /(?:ARCHS|ARGS)=.*/ =~ option
        # The ARCHS option is only applicable for xcodebuild, useful to specify a non-default arch to build when in Debug build configuration where ONLY_ACTIVE_ARCH is set to YES
        # The ARGS option is only applicable for make, useful to pass extra arguments while building a specific target, e.g. ARGS=-VV when the target is 'test' to turn on extra verbose mode
        build_options = "#{build_options} #{option}"
      elsif /unfilter=\W*?(?<unfilter_value>\w+)/ =~ option
        unfilter = !(/(?:true|yes|1)/i =~ unfilter_value).nil?
      elsif /verbosity=.*/ =~ option
        # The verbosity option is only applicable for msbuild when building RUN_TESTS, useful to specify the verbosity of the test output
        if ARGV.include?('target=RUN_TESTS')
          build_options = "#{build_options} /#{option.gsub(/=/, ':')}"
          unfilter = true
        end
      elsif /(?:build_tree|numjobs)=.*/ !~ option
        build_options = "#{build_options} #{/=/ =~ option ? '-' + option.gsub(/=/, ' ') : option}"
      end
    end
  }
  build_tree = ENV["#{platform}_build_tree"] || ENV['build_tree'] || "build/#{platform}"
  if ENV['OS']
    # While calling mingw-32-make itself does not require the PATH to be altered (as long as it is not inside an MSYS shell),
    # we have to do it again here because our build system invokes CMake internally to generate things on-the-fly as part of the build process
    ENV['PATH'] = ENV['PATH'].gsub /Git\\usr\\bin/, 'GoAway'
  else
    ccache_envvar = ENV['CCACHE_SLOPPINESS'] ? '' : 'CCACHE_SLOPPINESS=pch_defines,time_macros'   # Only attempt to do the right thing when user hasn't done it
    ccache_envvar = "#{ccache_envvar} CCACHE_COMPRESS=1" unless ENV['CCACHE_COMPRESS']
  end
  if !Dir.glob("#{build_tree}/*.xcodeproj").empty?
    # xcodebuild
    if !numjobs.empty?
      build_options = "-jobs #{numjobs}#{build_options}"
    end
    filter = !unfilter && !ARGV.include?('target=RUN_TESTS') && system('xcpretty -v >/dev/null 2>&1') ? '|xcpretty -c && exit ${PIPESTATUS[0]}' : ''
  elsif !Dir.glob("#{build_tree}\\*.sln".gsub(/\\/, '/')).empty?
    # msbuild
    numjobs = ":#{numjobs}" unless numjobs.empty?
    build_options = "/maxcpucount#{numjobs}#{build_options}"
    filter = unfilter ? '' : '/nologo /verbosity:minimal'
    filter = filter  + ' /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll"' if ENV['APPVEYOR']
  elsif !Dir.glob("#{build_tree}/*.ninja").empty?
    # ninja
    if !numjobs.empty?
      build_options = "-j#{numjobs}#{build_options}"
    end
    filter = ''
  else
    # make
    if numjobs.empty?
      case RUBY_PLATFORM
      when /linux/
        numjobs = `grep -c processor /proc/cpuinfo`.chomp
      when /darwin/
        numjobs = `sysctl -n hw.#{platform == 'web' ? 'physical' : 'logical'}cpu`.chomp
      when /win32|mingw|mswin/
        require 'win32ole'
        WIN32OLE.connect('winmgmts://').ExecQuery("select NumberOf#{platform == 'web' ? '' : 'Logical'}Processors from Win32_ComputerSystem").each { |out| numjobs = platform == 'web' ? out.NumberOfProcessors : out.NumberOfLogicalProcessors }
      else
        numjobs = 1
      end
    end
    build_options = "-j#{numjobs}#{build_options}"
    filter = ''
  end
  system "cd \"#{build_tree}\" && #{ccache_envvar} cmake --build . #{cmake_build_options} -- #{build_options} #{filter}" or abort
end

### Tasks for Urho3D maintainers ###

# Usage: rake git remote_add|sync|subtree
desc 'Collections of convenience git commands, multiple git commands may be executed in one rake command'
task :git do
  success = true
  consumed = false
  ARGV.each_with_index { |command, index|
    task command.to_sym do ; end; Rake::Task[command].clear   # No-op hack
    next if consumed
    case command
    when 'remote_add', 'sync', 'subtree'
      success = system "rake git_#{ARGV[index, ARGV.length - index].delete_if { |arg| /=/ =~ arg }.join ' '}"
      consumed = true
    else
      abort 'Usage: rake git remote_add|sync|subtree' unless command == 'git' && ARGV.length > 1
    end
  }
  abort unless success
end

# Usage: rake git remote_add [remote=<local-name>] url=<remote-url>'
desc 'Add a new remote and configure it so that its tags will be fetched into a unique namespace'
task :git_remote_add do
  abort 'Usage: rake git remote_add [remote=<name>] url=<remote-url>' unless ENV['url']
  remote = ENV['remote'] || /\/(.*?)\.git/.match(ENV['url'])[1]
  system "git remote add #{remote} #{ENV['url']} && git config --add remote.#{remote}.fetch +refs/tags/*:refs/tags/#{remote}/* && git config remote.#{remote}.tagopt --no-tags && git fetch #{remote}" or abort
end

# Usage: rake git sync [master=master] [upstream=upstream]
desc "Fetch and merge an upstream's remote branch to a fork's local branch then pushing the local branch to the fork's corresponding remote branch"
task :git_sync do
  master = ENV['master'] || 'master'
  upstream = ENV['upstream'] || 'upstream'
  system "git fetch #{upstream} && git checkout #{master} && git merge -m 'Sync at #{Time.now.localtime}.' #{upstream}/#{master} && git push && git checkout -" or abort
end

# Usage: rake git subtree split|rebase|add|push|pull
desc 'Misc. sub-commands for git subtree operations'
task :git_subtree do
  ARGV.each { |subcommand|
    task subcommand.to_sym do ; end; Rake::Task[subcommand].clear   # No-op hack
    case subcommand
    when 'split'
      abort 'Usage: rake git subtree split subdir=</path/to/subdir/to/be/split> [split_branch=<name>]' unless ENV['subdir']
      ENV['split_branch'] = "#{Pathname.new(ENV['subdir']).basename}-split" unless ENV['split_branch']
      system "git subtree split --prefix #{ENV['subdir']} -b #{ENV['split_branch']}" or abort
    when 'rebase'
      abort 'Usage: rake git subtree rebase baseline=<commit|branch|tag> split_branch=<name>' unless ENV['baseline'] && ENV['split_branch']
      ENV['rebased_branch'] = "#{Pathname.new(ENV['baseline']).basename}-#{ENV['rebased_branch_suffix'] || 'modified-for-urho3d'}"
      head = `git log --pretty=format:'%H' #{ENV['split_branch']} |head -1`.chomp
      tail = `git log --reverse --pretty=format:'%H' #{ENV['split_branch']} |head -1`.chomp
      system "git rebase --onto #{ENV['baseline']} #{tail} #{head} && git checkout -b #{ENV['rebased_branch']}" or abort "After resolving all the conflicts, issue this command manually:\ngit checkout -b #{ENV['rebased_branch']}"
    when 'add'
      abort 'Usage: rake git subtree add subdir=</path/to/subdir/to/be/split> remote=<name> baseline=<commit|branch|tag>' unless ENV['subdir'] && ENV['remote'] && ENV['baseline']
      ENV['rebased_branch'] = "#{Pathname.new(ENV['baseline']).basename}-#{ENV['rebased_branch_suffix'] || 'modified-for-urho3d'}"
      system "git push -u #{ENV['remote']} #{ENV['rebased_branch']} && git rm -r #{ENV['subdir']} && git commit -qm 'Replace #{ENV['subdir']} subdirectory with subtree.' && git subtree add --prefix #{ENV['subdir']} #{ENV['remote']} #{ENV['rebased_branch']} --squash" or abort
    when 'push'
      abort 'Usage: rake git subtree push subdir=</path/to/subdir/to/be/split> remote=<name> baseline=<commit|branch|tag>' unless ENV['subdir'] && ENV['remote'] && ENV['baseline']
      ENV['rebased_branch'] = "#{Pathname.new(ENV['baseline']).basename}-#{ENV['rebased_branch_suffix'] || 'modified-for-urho3d'}"
      system "git subtree push --prefix #{ENV['subdir']} #{ENV['remote']} #{ENV['rebased_branch']}" or abort
    when 'pull'
      abort 'Usage: rake git subtree pull subdir=</path/to/subdir/to/be/split> remote=<name> baseline=<commit|branch|tag>' unless ENV['subdir'] && ENV['remote'] && ENV['baseline']
      ENV['rebased_branch'] = "#{Pathname.new(ENV['baseline']).basename}-#{ENV['rebased_branch_suffix'] || 'modified-for-urho3d'}"
      system "git subtree pull --prefix #{ENV['subdir']} #{ENV['remote']} #{ENV['rebased_branch']} --squash" or abort
    else
      abort 'Usage: rake git subtree split|rebase|add|push|pull' unless subcommand == 'git_subtree' && ARGV.length > 1
    end
  }
end



# Always call this function last in the multiple conditional check so that the checkpoint message does not being echoed unnecessarily
def timeup quiet = false, cutoff_time = ENV['RELEASE_TAG'] ? 60.0 : 45.0
  unless File.exists?('start_time.log')
    system 'touch start_time.log split_time.log' if ENV['CI']
    return nil
  end
  current_time = Time.now
  elapsed_time = (current_time - File.atime('start_time.log')) / 60.0
  unless quiet
    lap_time = (current_time - File.atime('split_time.log')) / 60.0
    system 'touch split_time.log'
    puts "\n=== elapsed time: #{elapsed_time.to_i} minutes #{((elapsed_time - elapsed_time.to_i) * 60.0).round} seconds, lap time: #{lap_time.to_i} minutes #{((lap_time - lap_time.to_i) * 60.0).round} seconds ===\n\n" unless File.exists?('already_timeup.log'); $stdout.flush
  end
  return system('touch already_timeup.log') if elapsed_time > cutoff_time
end

def scaffolding dir, project = 'Scaffolding', target = 'Main'
  begin
    dir = Pathname.new(dir).realdirpath.to_s
  rescue
    abort "Failed to scaffolding due to invalid parent directory in '#{dir}'"
  end
  dir.gsub!(/\//, '\\') if ENV['OS']
  build_script = <<EOF
# Set CMake minimum version and CMake policy required by UrhoCommon module
cmake_minimum_required (VERSION 3.10.2)
if (COMMAND cmake_policy)
    # Libraries linked via full path no longer produce linker search paths
    cmake_policy (SET CMP0003 NEW)
    # INTERFACE_LINK_LIBRARIES defines the link interface
    cmake_policy (SET CMP0022 NEW)
    # Disallow use of the LOCATION target property - so we set to OLD as we still need it
    cmake_policy (SET CMP0026 OLD)
    # MACOSX_RPATH is enabled by default
    cmake_policy (SET CMP0042 NEW)
    # Honor the visibility properties for SHARED target types only
    cmake_policy (SET CMP0063 OLD)
endif ()

# Set project name
project (#{project})

# Set CMake modules search path
set (CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/Modules)

# Include UrhoCommon.cmake module after setting project name
include (UrhoCommon)

# Define target name
set (TARGET_NAME #{target})

# Define source files
define_source_files ()

# Setup target with resource copying
setup_main_executable ()

# Setup test cases
if (URHO3D_ANGELSCRIPT)
    setup_test (NAME ExternalLibAS OPTIONS Scripts/12_PhysicsStressTest.as -w)
endif ()
if (URHO3D_LUA)
    setup_test (NAME ExternalLibLua OPTIONS LuaScripts/12_PhysicsStressTest.lua -w)
endif ()
EOF
  # TODO: Rewrite in pure Ruby when it supports symlink creation on Windows platform and avoid forward/backward slash conversion
  if ENV['OS']
    system("@echo off && mkdir \"#{dir}\"\\bin && copy Source\\Tools\\Urho3DPlayer\\Urho3DPlayer.* \"#{dir}\" >nul && (for %f in (script CMake) do mklink /D \"#{dir}\"\\%f %cd%\\%f >nul) && mklink \"#{dir}\"\\Rakefile %cd%\\Rakefile && (for %d in (Autoload,CoreData,Data) do mklink /D \"#{dir}\"\\bin\\%d %cd%\\bin\\%d >nul)") && File.write("#{dir}/CMakeLists.txt", build_script) or abort 'Failed to scaffolding'
  else
    system("bash -c \"mkdir -p '#{dir}'/bin && cp Source/Tools/Urho3DPlayer/Urho3DPlayer.* '#{dir}' && for f in script Rakefile CMake; do ln -snf `pwd`/\\$f '#{dir}'; done && ln -snf `pwd`/bin/{Autoload,CoreData,Data} '#{dir}'/bin\"") && File.write("#{dir}/CMakeLists.txt", build_script) or abort 'Failed to scaffolding'
  end
  return dir
end

def get_root_commit_and_recipients
  # Root commit is a commit submitted by human
  root_commit = `git show -s --format='%H' #{ENV['TRAVIS_COMMIT']}`.rstrip
  recipients = `git show -s --format='%ae %ce' #{root_commit}`.chomp.split.uniq
  if recipients.include? 'urho3d.travis.ci@gmail.com'
    matched = /Commit:.*commit\/(.*?)\n/.match(ENV['COMMIT_MESSAGE'])
    if (matched)
      root_commit = matched[1]
      recipients = `git show -s --format='%ae %ce' #{root_commit}`.chomp.split.uniq
    end
  end
  return root_commit, recipients
end

# Usage: wait_for_block('This is a long function call...') { call_a_func } or abort
#        wait_for_block('This is a long system call...') { system 'do_something' } or abort
def wait_for_block comment = '', cutoff_time = ENV['RELEASE_TAG'] ? 60.0 : 45.0, retries = -1, retry_interval = 60
  return nil if timeup(true, cutoff_time)

  # Wait until the code block is completed or it is killed externally by user via Ctrl+C or when it exceeds the number of retries (if the retries parameter is provided)
  thread = Thread.new { rc = yield; Thread.main.wakeup; rc }
  thread.priority = 1   # Make the worker thread has higher priority than the main thread
  str = comment
  retries = retries * 60 / retry_interval unless retries == -1
  until thread.status == false
    if retries == 0 || timeup(true, cutoff_time)
      thread.kill
      # Also kill the child subproceses spawned by the worker thread if specified
      system "killall #{thread[:subcommand_to_kill]}" if thread[:subcommand_to_kill]
      sleep 5
      break
    end
    print str; str = '.'; $stdout.flush   # Flush the standard output stream in case it is buffered to prevent Travis-CI into thinking that the build/test has stalled
    retries -= 1 if retries > 0
    sleep retry_interval
  end
  puts "\n" if str == '.'; $stdout.flush
  thread.join
  return thread.value
end

# Usage: retry_block { code-block } or abort
def retry_block retries = 10, retry_interval = 1
    until yield
        retries -= 1
        return nil if retries == 0
        sleep retry_interval
    end
    0
end

def append_new_release release, filename = 'build/urho3d.github.io/_data/urho3d.json'
  begin
    urho3d_hash = JSON.parse File.read filename
    unless urho3d_hash['releases'].last == release
      urho3d_hash['releases'] << release
    end
    File.open(filename, 'w') { |file| file.puts urho3d_hash.to_json }
    return 0
  rescue
    nil
  end
end

def update_web_samples_data dir = 'build/urho3d.github.io/samples', filename = 'build/urho3d.github.io/_data/web.json'
  begin
    web = { 'samples' => {} }
    Dir.chdir(dir) { web['samples']['Native'] = Dir['*.html'].sort }
    web['player'] = web['samples']['Native'].pop     # Assume the last sample after sorting is the Urho3DPlayer.html
    {'AngelScript' => 'Scripts', 'Lua' => 'LuaScripts'}.each { |lang, subdir|
      Dir.chdir("bin/Data/#{subdir}") {
        script_samples = Dir['[0-9]*'].sort
        deleted_samples = []    # Delete samples that do not have their native counterpart
        script_samples.each { |sample| deleted_samples.push sample unless web['samples']['Native'].include? "#{sample.split('.').first}.html" }
        web['samples'][lang] = (script_samples - deleted_samples).map { |sample| "#{subdir}/#{sample}" }
      }
    }
    File.open(filename, 'w') { |file| file.puts web.to_json }
    return 0
  rescue
    nil
  end
end

def bump_copyright_year dir='.', regex='2008-[0-9]{4} the Urho3D project'
  begin
    Dir.chdir dir do
      copyrighted = `git grep -El '#{regex}'`.split
      copyrighted.each { |filename|
        replaced_content = File.read(filename).gsub(/#{regex}/, regex.gsub('[0-9]{4}', Time.now.year.to_s))
        File.open(filename, 'w') { |file| file.puts replaced_content }
      }
      return copyrighted
    end
  rescue
    abort 'Failed to bump copyright year'
  end
end

def bump_soversion filename
  begin
    version = File.read(filename).split '.'
    bump_version version, 2
    File.open(filename, 'w') { |file| file.puts version.join '.' }
    return 0
  rescue
    nil
  end
end

def bump_version version, index
  if index > 0 && version[index].to_i == 255
    version[index] = 0
    bump_version version, index - 1
  else
    version[index] = version[index].to_i + 1
  end
end

def setup_digital_keys
  system "bash -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'" or abort 'Failed to create ~/.ssh directory'
  system "bash -c 'ssh-keyscan frs.sourceforge.net >>~/.ssh/known_hosts 2>/dev/null'" or abort 'Failed to append frs.sourceforge.net server public key to known_hosts'
  # Workaround travis encryption key size limitation. Rather than using the solution in their FAQ (using AES to encrypt/decrypt the file and check in the encrypted file into repo), our solution is more pragmatic. The private key below is incomplete. Only the missing portion is encrypted. Much less secure than the original 2048-bit RSA has to offer but good enough for our case.
  system "bash -c 'cat <<EOF >~/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAnZGzFEypdXKY3KDT0Q3NLY4Bv74yKgJ4LIgbXothx8w4CfM0
VeWBL/AE2iRISEWGB07LruM9y+U/wt58WlCVu001GuJuvXwWenlljsvH8qQlErYi
oXlCwAeVVeanILGL8CPS7QlyzOwwnVF6NdcmfDJjTthBVFbvHrWGo5if86zcZyMR
2BB5QVEr5fU0yOPFp0+2p7J3cA6HQSKwjUiDtJ+lM62UQp7InCCT3qeh5KYHQcYb
KVJTyj5iycVuBujHDwNAivLq82ojG7LcKjP+Ia8fblardCOQyFk6pSDM79NJJ2Dg
3ZbYIJeUmqSqFhRW/13Bro7Z1aNGrdh/XZkkHwIDAQABAoIBACHcBFJxYtzVIloO
yVWcFKIcaO3OLjNu0monWVJIu1tW3BfvRijLJ6aoejJyJ4I4RmPdn9FWDZp6CeiT
LL+vn21fWvELBWb8ekwZOCSmT7IpaboKn4h5aUmgl4udA/73iC2zVQkQxbWZb5zu
vEdDk4aOwV5ZBDjecYX01hjjnEOdZHGJlF/H/Xs0hYX6WDG3/r9QCJJ0nfd1/Fk2
zdbZRtAbyRz6ZHiYKnFQ441qRRaEbzunkvTBEwu9iqzlE0s/g49LJL0mKEp7rt/J
4iS3LZTQbJNx5J0ti8ZJKHhvoWb5RJxNimwKvVHC0XBZKTiLMrhnADmcpjLz53F8
#{ENV['SF_KEY']}
sx27yCaeBeKXV0tFOeZmgK664VM9EgesjIX4sVOJ5mA3xBJBOtz9n66LjoIlIM58
dvsAnJt7MUBdclL/RBHEjbUxgGBDcazfWSuJe0sGczhnXMN94ox4MSECgYEAx5cv
cs/2KurjtWPanDGSz71LyGNdL/xQrAud0gi49H0tyYr0XmzNoe2CbZ/T5xGSZB92
PBcz4rnHQ/oujo/qwjNpDD0xVLEU70Uy/XiY5/v2111TFC4clfE/syZPywKAztt3
y2l5z+QdsNigRPDhKw+7CFYaAnYBEISxR6nabT8CgYEAqHrM8fdn2wsCNE6XvkZQ
O7ZANHNIKVnaRqW/8HW7EFAWQrlQTgzFbtR4uNBIqAtPsvwSx8Pk652+OR1VKfSv
ya3dtqY3rY/ErXWyX0nfPQEbYj/oh8LbS6zPw75yIorP3ACIwMw3GRNWIvkdAGTn
BMUgpWHUDLWWpWRrSzNi90ECgYEAkxxzQ6vW5OFGv17/NdswO+BpqCTc/c5646SY
ScRWFxbhFclOvv5xPqYiWYzRkmIYRaYO7tGnU7jdD9SqVjfrsAJWrke4QZVYOdgG
cl9eTLchxLGr15b5SOeNrQ1TCO4qZM3M6Wgv+bRI0h2JW+c0ABpTIBzehOvXcwZq
6MhgD98CgYEAtOPqc4aoIRUy+1oijpWs+wU7vAc8fe4sBHv5fsv7naHuPqZgyQYY
32a54xZxlsBw8T5P4BDy40OR7fu+6miUfL+WxUdII4fD3grlIPw6bpNE0bCDykv5
RLq28S11hDrKf/ZetXNuIprfTlhl6ISBy+oWQibhXmFZSxEiXNV6hCQ=
-----END RSA PRIVATE KEY-----
EOF'" or abort 'Failed to create user private key to id_rsa'
  system "bash -c 'chmod 600 ~/.ssh/id_rsa'" or abort 'Failed to change id_rsa file permission'
end

# Load custom rake scripts
Dir['.rake/*.rake'].each { |r| load r }

# vi: set ts=2 sw=2 expandtab:
