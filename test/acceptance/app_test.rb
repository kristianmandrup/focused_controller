require 'helper'
require 'capybara'
require 'capybara_minitest_spec'
require 'capybara/poltergeist'
require 'socket'

module FocusedController
  module Test
    def self.port
      @port ||= begin
        server = TCPServer.new('127.0.0.1', 0)
        port   = server.addr[1]
      ensure
        server.close if server
      end
    end
  end
end

Capybara.run_server = false
Capybara.app_host   = "http://127.0.0.1:#{FocusedController::Test.port}"

describe 'acceptance test' do
  # This spawns a server process to run the app under test,
  # and then waits for it to successfully come up so we can
  # actually run the test.
  before do
    output = IO.pipe
    @pid = Kernel.spawn(
      { 'BUNDLE_GEMFILE' => TEST_ROOT + '/app/Gemfile' },
      "bundle exec rails s -p #{FocusedController::Test.port}",
      :chdir => TEST_ROOT + '/app',
      :out => output[1], :err => output[1]
    )

    start   = Time.now
    started = false

    while !started && Time.now - start <= 15.0
      begin
        sleep 0.1
        TCPSocket.new('127.0.0.1', FocusedController::Test.port)
      rescue Errno::ECONNREFUSED
      else
        started = true
      end
    end

    unless started
      puts "Server failed to start"
      puts "Output:"
      puts

      loop do
        begin
          print output[0].read_nonblock(1024)
        rescue Errno::EWOULDBLOCK, Errno::EAGAIN
          puts
          break
        end
      end

      raise
    end
  end

  after do
    Process.kill('TERM', @pid)
  end

  let(:s) { Capybara::Session.new(:poltergeist, nil) }

  it 'does basic CRUD actions successfully' do
    s.visit '/posts'

    s.click_link 'New Post'
    s.fill_in 'Title', :with => 'Hello world'
    s.fill_in 'Body',  :with => 'Omg, first post'
    s.click_button 'Create Post'

    s.click_link 'Back'
    s.must_have_content 'Hello world'
    s.must_have_content 'Omg, first post'

    s.click_link 'Show'
    s.must_have_content 'Hello world'
    s.must_have_content 'Omg, first post'

    s.click_link 'Edit'
    s.fill_in 'Title', :with => 'Goodbye world'
    s.fill_in 'Body',  :with => 'Omg, edited'
    s.click_button 'Update Post'
    s.must_have_content 'Goodbye world'
    s.must_have_content 'Omg, edited'

    s.click_link 'Back'
    s.click_link 'Destroy'
    s.wont_have_content 'Goodbye world'
    s.wont_have_content 'Omg, edited'
  end
end
